pragma solidity ^0.5.1;

import "./SafeMath.sol";

import "./IceGlobal.sol";
import "./IceSort.sol";

/**
 * @title Ice Protocol Files / Groups / Users Meta Management System Libray
 * @author Harsh Rajat
 * @notice Create sorting order for maximizing space utilization
 * @dev This Library is part of many that Ice uses form a robust File Management System
 */
library IceFMSAdv {
    using SafeMath for uint;
    
    using IceGlobal for IceGlobal.GlobalRecord;
    using IceGlobal for IceGlobal.Association;
    using IceGlobal for IceGlobal.UserMeta;
    using IceGlobal for mapping (uint => bool);
    using IceGlobal for mapping (uint8 => IceGlobal.ItemOwner);
    using IceGlobal for uint;
    
    using IceSort for mapping (uint => IceSort.SortOrder);
    
    /* ***************
    * DEFINE EVENTS | DUPLICATE / TRICK - https://blog.aragon.org/library-driven-development-in-solidity-2bebcaf88736/
    *************** */
    // When Sharing is completed
    event SharingCompleted(uint EIN, uint index1, uint index2, uint recipientEIN);
    
    // When Sharing is rejected
    event SharingRejected(uint EIN, uint index1, uint index2, uint recipientEIN);
    
    // When Sharing is removed
    event SharingRemoved(uint EIN, uint index1, uint index2, uint recipientEIN);
   
    /* ***************
    * DEFINE STRUCTURES
    *************** */
     
    /* ***************
    * DEFINE FUNCTIONS
    *************** */
    // 1. SHARING FUNCTIONS
    /**
     * @dev Function to share an item to other users, always called by owner of the Item
     * @param self is the mappings of all pointer to the GlobalRecord Struct (IceGlobal Library) which forms shares in Ice Contract
     * @param _globalItems is the mapping of all items stored by all users in the Ice FMS
     * @param _totalShareOrderMapping is the mapping of the entire shares order using SortOrder Struct (IceSort Library)
     * @param _shareCountMapping is the mapping of all share count
     * @param _blacklist is the entire mapping of the Blacklist for all users
     * @param _rec is the GlobalRecord Struct (IceGlobal Library)
     * @param _ein is the primary user who initiates sharing of the item
     * @param _toEINs is the array of the users with whom the item will be shared
     */
    function shareItemToEINs(
        mapping (uint => mapping(uint => IceGlobal.GlobalRecord)) storage self, 
        mapping (uint => mapping(uint => IceGlobal.Association)) storage _globalItems, 
        mapping (uint => mapping(uint => IceSort.SortOrder)) storage _totalShareOrderMapping, 
        mapping (uint => uint) storage _shareCountMapping,
        mapping (uint => mapping(uint => bool)) storage _blacklist, 
        IceGlobal.GlobalRecord storage _rec, 
        uint _ein, 
        uint[] calldata _toEINs
    )
    external {
        // Warn: Unbounded Loop
        for (uint i=0; i < _toEINs.length; i++) {
            // call share for each EIN you want to share with
            // Since its multiple share, don't put require blacklist but ignore the share
            // if owner of the file is in blacklist
            if (_blacklist[_toEINs[i]][_ein] == false && (_ein != _toEINs[i])) {
                // track new count
                _shareItemToEIN(
                    self[_toEINs[i]], 
                    _globalItems, 
                    _totalShareOrderMapping[_toEINs[i]], 
                    _shareCountMapping, 
                    _rec, 
                    _toEINs[i]
                );
                
                // Trigger Event
                emit SharingCompleted(_ein, _rec.i1, _rec.i2, _toEINs[i]);
            }
            else {
                // Trigger Event
                emit SharingRejected(_ein, _rec.i1, _rec.i2, _toEINs[i]);
            }
        }
    }
    
    /**
     * @dev Function to share an item to a specific user, always called by owner of the Item
     * @param self is the mappings of all shares associated with the recipient user
     * @param _globalItems is the mapping of all items stored by all users in the Ice FMS
     * @param _shareOrder is the mapping of the shares order using SortOrder Struct (IceSort Library) of the recipient user
     * @param _shareCount is the mapping of all share count
     * @param _rec is the GlobalRecord Struct (IceGlobal Library)
     * @param _toEIN is the ein of the recipient user 
     */
    function _shareItemToEIN(
        mapping (uint => IceGlobal.GlobalRecord) storage self, 
        mapping (uint => mapping (uint => IceGlobal.Association)) storage _globalItems, 
        mapping (uint => IceSort.SortOrder) storage _shareOrder, 
        mapping (uint => uint) storage _shareCount, 
        IceGlobal.GlobalRecord storage _rec, 
        uint _toEIN
    )
    internal {
        // Logic
        // Check if the item is already shared or not and do the operation accordingly
        if (!_rec.getGlobalItemViaRecord(_globalItems).sharedToEINMapping[_toEIN]) {
            // Create Sharing
            uint curIndex = _shareCount[_toEIN];
            uint nextIndex = curIndex.add(1);
            
            // no need to require as share can be multiple
            // and thus should not hamper other sharings
            if (nextIndex > curIndex) {
                self[nextIndex] = _rec;
    
                // Add to share order & global mapping
                _shareCount[_toEIN] = _shareOrder.addToSortOrder(_shareOrder[0].prev, _shareCount[_toEIN], 0);
                
                IceGlobal.Association storage globalItem = self[nextIndex].getGlobalItemViaRecord(_globalItems);
                globalItem.addToGlobalItemsMapping(uint8(IceGlobal.AsscProp.sharedTo), _toEIN, nextIndex);
            }
            
        }
    }

    /**
     * @dev Function to remove all shares of an Item, always called by owner of the Item
     * @param self is the mappings of all pointer to the GlobalRecord Struct (IceGlobal Library) which forms shares in Ice Contract
     * @param _ein is the ein of the primary user
     * @param _globalItemIndividual is the Association Struct (IceGlobal Library) that contains additional info about file
     * @param _shareOrderMapping is the mapping of the entire shares order using SortOrder Struct (IceSort Library)
     * @param _shareCountMapping is the mapping of all share count
     */
    function removeAllShares(
        mapping (uint => mapping(uint => IceGlobal.GlobalRecord)) storage self,
        uint _ein,
        IceGlobal.Association storage _globalItemIndividual,
        mapping (uint => mapping(uint => IceSort.SortOrder)) storage _shareOrderMapping, 
        mapping (uint => uint) storage _shareCountMapping
    ) 
    external {
        if (_globalItemIndividual.sharedToCount > 0) {
            // Logic
            // get and pass all EINs, remove share takes care of locking
            uint[] memory fromEINs = _globalItemIndividual.sharedTo.getHistoralEINsForGlobalItems(_globalItemIndividual.sharedToCount);
            
            // Remove item from share
            removeShareFromEINs(
                self, 
                _ein, 
                fromEINs,
                _globalItemIndividual, 
                _shareOrderMapping, 
                _shareCountMapping
            );
        }
    }
    
    /**
     * @dev Function to remove a shared item from the multiple user's mapping, always called by owner of the Item
     * @param self is the mappings of all pointer to the GlobalRecord Struct (IceGlobal Library) which forms shares in Ice Contract
     * @param _ein is the ein of the primary user
     * @param _globalItemIndividual is the Association Struct (IceGlobal Library) that contains additional info about file
     * @param _shareOrderMapping is the mapping of the entire shares order using SortOrder Struct (IceSort Library)
     * @param _shareCountMapping is the mapping of all share count
     */
    function removeShareFromEINs(
        mapping (uint => mapping(uint => IceGlobal.GlobalRecord)) storage self,
        uint _ein,
        uint[] memory _fromEINs,
        IceGlobal.Association storage _globalItemIndividual,
        mapping (uint => mapping(uint => IceSort.SortOrder)) storage _shareOrderMapping, 
        mapping (uint => uint) storage _shareCountMapping
    )
    public {
        // Adjust for valid loop
        uint scount = 0;
        
        while (scount < _fromEINs.length) {
            // call share for each EIN you want to remove the share
            if (_ein != _fromEINs[scount]) {
                // remove individual share 
                _removeShareFromEIN(
                    self[_fromEINs[scount]], 
                    _fromEINs[scount],
                    _globalItemIndividual, 
                    _shareOrderMapping[_fromEINs[scount]], 
                    _shareCountMapping
                );
            }
            
            scount = scount.add(1);
        }
    }
    
    /**
     * @dev Private Function to remove a shared item from the user's mapping
     * @param self is the mappings of all shares associated with the recipient user
     * @param _fromEIN is the ein of the recipient user
     * @param _globalItemIndividual is the Association Struct (IceGlobal Library) that contains additional info about file
     * @param _shareOrderMapping is the mapping of the entire shares order using SortOrder Struct (IceSort Library)
     * @param _shareCountMapping is the mapping of all share count
     */
    function _removeShareFromEIN(
        mapping (uint => IceGlobal.GlobalRecord) storage self,
        uint _fromEIN,
        IceGlobal.Association storage _globalItemIndividual,
        mapping (uint => IceSort.SortOrder) storage _shareOrderMapping, 
        mapping (uint => uint) storage _shareCountMapping
    )
    internal {
        // Logic
        // Create Sharing
        uint curIndex = _shareCountMapping[_fromEIN];

        // no need to require as share can be multiple
        // and thus should not hamper other sharings removals
        if (curIndex > 0) {
            uint8 mappedIndex;
            bool itemFound;
            
            (mappedIndex, itemFound) = _globalItemIndividual.sharedTo.findItemOwnerInGlobalItems(_globalItemIndividual.sharedToCount, _fromEIN);
            
            // Only proceed if mapping if found 
            if (itemFound) {
                uint _itemIndex = _globalItemIndividual.sharedTo[mappedIndex].index;
                
                // Remove the share from global items mapping
                _globalItemIndividual.removeFromGlobalItemsMapping(uint8(IceGlobal.AsscProp.sharedTo), mappedIndex);
                
                // Swap the shares, then Remove from share order & stich
                self[_itemIndex] = self[curIndex];
                _shareCountMapping[_fromEIN] = _shareOrderMapping.stichSortOrder(_itemIndex, curIndex, 0);
                
                // Trigger Event
                emit SharingRejected(_globalItemIndividual.ownerInfo.EIN, self[curIndex].i1, self[curIndex].i2, _fromEIN);
                
                // Delete the latest shares now
                delete (self[curIndex]);
            }
        }
    }
    
    /**
     * @dev Function to remove shared item by the user to whom the item is shared
     * @param self is the mappings of all shares associated with the recipient user (ie Sharee)
     * @param _shareeEIN is the ein of the recipient user
     * @param _globalItemIndividual is the Association Struct (IceGlobal Library) that contains additional info about file
     * @param _shareOrderMapping is the mapping of the entire shares order using SortOrder Struct (IceSort Library)
     * @param _shareCountMapping is the mapping of all share count
     */
    function removeSharingItemBySharee(
        mapping (uint => IceGlobal.GlobalRecord) storage self,
        uint _shareeEIN,
        IceGlobal.Association storage _globalItemIndividual,
        mapping (uint => IceSort.SortOrder) storage _shareOrderMapping, 
        mapping (uint => uint) storage _shareCountMapping
    ) 
    external {
        // Logic
        _removeShareFromEIN(
            self, 
            _shareeEIN,
            _globalItemIndividual, 
            _shareOrderMapping, 
            _shareCountMapping
        );
    }
    
    // 2. STAMPING FUNCTIONS
    /**
     * @dev Function to initiate stamping of an item by the owner of that item
     * @param self is the mappings of stamping requests associated with the recipient user
     * @param _stampingReqOrderMapping is the mapping of the stamping request order using SortOrder Struct (IceSort Library) of the recipient
     * @param _stampingReqCountMapping is the mapping of all stamping requests count
     * @param _ownerEIN is the owner EIN of the user who has initiated the stamping of the item
     * @param _recipientEIN is the recipient EIN of the user who has to stamp the item
     * @param _itemIndex is the index of the item (File or Group)
     * @param _itemCount is the count of the number of items (File or Group) the owner has 
     * @param _globalItem is the Association Struct (IceGlobal Library) of the item in question
     * @param _record is the GlobalRecord Struct (IceGlobal Library) of the item in question
     * @param _blacklist is the entire mapping of the Blacklist for all users
     * @param _identityRegistry is the pointer to the ERC-1484 Identity Registry
     */
    function initiateStampingOfItem(
        mapping (uint => IceGlobal.GlobalRecord) storage self,
        mapping (uint => IceSort.SortOrder) storage _stampingReqOrderMapping, 
        mapping (uint => uint) storage _stampingReqCountMapping,
        
        uint _ownerEIN,
        uint _recipientEIN,
        uint _itemIndex,
        uint _itemCount,
        
        IceGlobal.Association storage _globalItem,
        IceGlobal.GlobalRecord storage _record,
        
        mapping (uint => mapping(uint => bool)) storage _blacklist,
        IdentityRegistryInterface _identityRegistry
    )
    external {
        // Check Constraints
        _itemIndex.condValidItem(_itemCount); // Check if item is valid
        _globalItem.condUnstampedItem(); // Check if the file is unstamped
        IceGlobal.condEINExists(_recipientEIN, _identityRegistry); // Check Valid EIN
        IceGlobal.condUniqueEIN(_ownerEIN, _recipientEIN); // Check EINs and Unique
        _blacklist[_recipientEIN].condNotInList(_ownerEIN); // Check if The recipient hasn't blacklisted the file owner
        
        // Logic
        // Flip the switch to indicate stamping is initiated, flush out any rejected message as well 
        _globalItem.stampingInitiated = uint32(now);
        _globalItem.stampingRejected = false;
       
        // Add reference of Item for the recipient
        uint nextStampingReqIndex = _stampingReqCountMapping[_recipientEIN].add(1);
        self[nextStampingReqIndex] = _record;
        
        // Add to Stitch Order & Increment index
        _stampingReqCountMapping[_recipientEIN] = _stampingReqOrderMapping.addToSortOrder(
            _stampingReqOrderMapping[0].prev, 
            _stampingReqCountMapping[_recipientEIN], 
            0
        );       
        
        // Add the recipient to indicate who should stamp the file and where it is in stamping request mapping
        _globalItem.addToGlobalItemsMapping(uint8(IceGlobal.AsscProp.stampedTo), _recipientEIN, nextStampingReqIndex);
    }
    
    /**
     * @dev Function to accept stamping of an item by the intended recipient
     * @param self is the mappings of completed stamping associated with the recipient user
     * @param _stampingOrderMapping is the mapping of the completed stamping order using SortOrder Struct (IceSort Library) of the recipient
     * @param _stampingCountMapping is the mapping of completed stamping count
     * @param _stampingsReq is the mappings of stamping requests associated with the recipient user
     * @param _stampingReqOrderMapping is the mapping of the stamping request order using SortOrder Struct (IceSort Library) of the recipient
     * @param _stampingReqCountMapping is the mapping of all stamping requests count
     * @param _globalItem is the Association Struct (IceGlobal Library) of the item in question
     * @param _recipientEIN is the recipient EIN of the user who has to stamp the item
     * @param _stampingReqIndex is the index of the item present in the Stamping Requests mapping of the recipient
     */
    function acceptStamping(
        mapping (uint => IceGlobal.GlobalRecord) storage self,
        mapping (uint => IceSort.SortOrder) storage _stampingOrderMapping, 
        mapping (uint => uint) storage _stampingCountMapping,
        
        mapping (uint => IceGlobal.GlobalRecord) storage _stampingsReq,
        mapping (uint => IceSort.SortOrder) storage _stampingReqOrderMapping, 
        mapping (uint => uint) storage _stampingReqCountMapping,
        
        IceGlobal.Association storage _globalItem,
        
        uint _recipientEIN,
        uint _stampingReqIndex
    )
    external {
        // Check constraints
        _stampingReqIndex.condValidItem(_stampingReqCountMapping[_recipientEIN]); // Check if item is valid
        
        // Logic
        // Add to Stamping Mapping of the user
        uint nextIndex = _stampingCountMapping[_recipientEIN].add(1);
        
        // Swap the stamping request, then Remove from stamping request order & stich for recipient
        self[nextIndex] = _stampingsReq[_stampingReqIndex];
        _stampingCountMapping[_recipientEIN] = _stampingOrderMapping.addToSortOrder(_stampingOrderMapping[0].prev, _stampingCountMapping[_recipientEIN], 0);
        
        // Swap the stamping request, then Remove from stamping request order & stich for recipient
        _removeStampingReq (
            _stampingsReq,
            _stampingReqOrderMapping,
            _stampingReqCountMapping,
            _recipientEIN,
            _stampingReqIndex,
            _globalItem
        );
        
        // Update the stamping flags
        _globalItem.stampingCompleted = uint32(now);
    }
    
    /**
     * @dev Function to cancel stamping of an item by either the owner or the recipient
     * @param self is the mappings of stamping requests associated with the recipient user
     * @param _stampingReqOrderMapping is the mapping of the stamping request order using SortOrder Struct (IceSort Library) of the recipient
     * @param _stampingReqCountMapping is the mapping of all stamping requests count
     * @param _recipientEIN is the recipient EIN of the user who has to stamp the item
     * @param _recipientItemIndex is the index of the item present in the Stamping Requests mapping of the recipient
     * @param _globalItem is the Association Struct (IceGlobal Library) of the item in question
     */
    function cancelStamping(
        mapping (uint => IceGlobal.GlobalRecord) storage self,
        mapping (uint => IceSort.SortOrder) storage _stampingReqOrderMapping, 
        mapping (uint => uint) storage _stampingReqCountMapping,
    
        uint _recipientEIN,
        uint _recipientItemIndex,
        
        IceGlobal.Association storage _globalItem
    )
    external {
        // Check constraints
        _recipientItemIndex.condValidItem(_stampingReqCountMapping[_recipientEIN]); // Check if item is valid
        _globalItem.condStampedItem(); // Check if the item has initiated stamping
        _globalItem.condUncompleteStamping(); // Check if the item hasn't completed stamping
        
        // Logic
        uint curIndex = _stampingReqCountMapping[_recipientEIN];
        
        // Swap the stamping request, then Remove from stamping request order & stich for recipient
        _removeStampingReq (
            self,
            _stampingReqOrderMapping,
            _stampingReqCountMapping,
            _recipientEIN,
            _recipientItemIndex,
            _globalItem
        );
        
        // Reset the stamping flag
        _globalItem.stampingInitiated = 0;
        
        // Delete the latest shares now
        delete (self[curIndex]);
    }
    
    /**
     * @dev Private Function to remove stamping of an item
     * @param self is the mappings of stamping requests associated with the recipient user
     * @param _stampingReqOrderMapping is the mapping of the stamping request order using SortOrder Struct (IceSort Library) of the recipient
     * @param _stampingReqCountMapping is the mapping of all stamping requests count
     * @param _recipientEIN is the recipient EIN of the user who has to stamp the item
     * @param _recipientItemIndex is the index of the item present in the Stamping Requests mapping of the recipient
     * @param _globalItem is the Association Struct (IceGlobal Library) of the item in question
     */
    function _removeStampingReq(
        mapping (uint => IceGlobal.GlobalRecord) storage self,
        mapping (uint => IceSort.SortOrder) storage _stampingReqOrderMapping, 
        mapping (uint => uint) storage _stampingReqCountMapping,
        
        uint _recipientEIN,
        uint _recipientItemIndex,
        
        IceGlobal.Association storage _globalItem
    )
    private {
        // Logic
        uint curIndex = _stampingReqCountMapping[_recipientEIN];
        
        // Swap the stamping request, then Remove from stamping request order & stich for recipient
        self[_recipientItemIndex] = self[curIndex];
        _stampingReqCountMapping[_recipientEIN] = _stampingReqOrderMapping.stichSortOrder(_recipientItemIndex, curIndex, 0);
        
        // Lastly update the remapped item stamping request index stored in the association struct
        _globalItem.stampingRecipient.index = curIndex;
    }
}