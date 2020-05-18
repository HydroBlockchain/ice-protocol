pragma solidity ^0.5.1;

import "./SafeMath.sol";
import "./SafeMath8.sol";

import "./IdentityRegistryInterface.sol";

/**
 * @title Ice Protocol Global Items Libray
 * @author Harsh Rajat
 * @notice Create and handle critical File Management functions
 * @dev This Library is part of many that Ice uses form a robust File Management System
 */
library IceGlobal {
    using SafeMath for uint;
    using SafeMath8 for uint8;

    /* ***************
    * DEFINE ENUM
    *************** */
    enum AsscProp {sharedTo, stampedTo}
    
    /* ***************
    * DEFINE STRUCTURES
    *************** */
    /* To define Global Record for a given Item */
    struct GlobalRecord {
        uint i1; // store associated global index 1 for access
        uint i2; // store associated global index 2 for access
    }
    
    /* To define ownership info of a given Item. */
    struct ItemOwner {
        uint EIN; // the EIN of the owner
        uint index; // the key at which the item is stored
    }

    /* To define global file association with EIN
     * Combining EIN and itemIndex and properties will give access to
     * item data.
     */
    struct Association {
        ItemOwner ownerInfo; // To Store Iteminfo
        ItemOwner stampingRecipient;  // to store stamping recipient

        bool isFile; // whether the Item is File or Group
        bool isHidden; // Whether the item is hidden or not
        bool deleted; // whether the association is deleted

        uint32 stampingInitiated; // Whether the item stamping is initiated, contains 0 or the timestamp
        uint32 stampingCompleted; // Whether the stamping is completed, contains 0 or the timestamp
        bool stampingRejected; // Whether the staping is rejected by recipient
        
        uint8 sharedToCount; // the count of sharing

        mapping (uint8 => ItemOwner) sharedTo; // to contain share to
        mapping (uint => bool) sharedToEINMapping; // contains EIN Mapping of shared to
    }
    
    /* To define state and flags for Individual things,
     * used in cases where state change should be atomic
     */
     struct UserMeta {
        bool hasAvatar;
     }
    
    /* ***************
    * DEFINE FUNCTIONS
    *************** */
    // 1. GLOBAL ITEMS
    /**
     * @dev Function to get global items info from the entire File Management System of Ice
     * @param self is the Association Struct (IceGlobal) which keeps tracks of item properties
     * @return ownerEIN is the EIN of the owner
     * @return itemRecord is the item index mapped for the specific user
     * @return isFile indicates if the item is a File or a Group
     * @return isHidden indicates if the item has been hidden
     * @return deleted indicates if the item has been deleted
     * @return sharedToCount is sharing count of that item
     */
    function getGlobalItems(Association storage self)
    external view
    returns (
        uint ownerEIN, 
        uint itemRecord, 
        bool isFile, 
        bool isHidden, 
        bool deleted, 
        uint sharedToCount
    ) {
        ownerEIN = self.ownerInfo.EIN;
        itemRecord = self.ownerInfo.index;

        isFile = self.isFile;
        isHidden = self.isHidden;
        deleted = self.deleted;

        sharedToCount = self.sharedToCount;
    }
    
    /**
     * @dev Function to get global items stamping info from the entire File Management System of Ice
     * @param self is the Association Struct (IceGlobal) which keeps tracks of item properties
     * @return stampingRecipient is the EIN of the recipient for whom stamping is requested / denied / completed
     * @return stampingRecipientIndex is the item index mapped in the mapping of stampingsReq of that recipient
     * @return stampingInitiated either returns 0 (false) or timestamp when the stamping was initiated
     * @return stampingCompleted either returns 0 (false) or timestamp when the stamping was completed
     * @return stampingRejected indicates if the stamping was rejected by the recipient
     */
    function getGlobalItemsStampingInfo(Association storage self)
    external view
    returns (
        uint stampingRecipient,
        uint stampingRecipientIndex,
        uint32 stampingInitiated,
        uint32 stampingCompleted,
        bool stampingRejected
    ) {
        stampingRecipient = self.stampingRecipient.EIN;
        stampingRecipientIndex = self.stampingRecipient.index;
        
        stampingInitiated = self.stampingInitiated;
        stampingCompleted = self.stampingCompleted;
        stampingRejected = self.stampingRejected;
    }
    
    /**
     * @dev Function to get global item via the Association Struct (IceGlobal library)
     * @param self is the GlobalRecord Struct (IceGlobal library) which contains the indexes used for storing an item
     * @param _globalItems is the entire array of global items
     * @return association is the Association Struct which contains properties of the specific item in question
     */
    function getGlobalItemViaRecord(
        GlobalRecord storage self, 
        mapping (uint => mapping(uint => Association)) storage _globalItems
    )
    internal view
    returns (Association storage association) {
        association = _globalItems[self.i1][self.i2];
    }
    
    /**
     * @dev Function to get global indexes via the Struct GlobalRecord (IceGlobal library)
     * @param self is the GlobalRecord Struct (IceGlobal library) which contains the indexes mapping of the item
     * @return i1 is the first index mapping
     * @return i2 is the second index mapping
     */
    function getGlobalIndexesViaRecord(GlobalRecord storage self)
    external view
    returns (
        uint i1, 
        uint i2
    ) {
        i1 = self.i1;
        i2 = self.i2;
    }
    
    /**
     * @dev Function to reserve and return global item slot
     * @param index1 is the initial first index of global item
     * @param index2 is the initial second index of global item 
     * @return globalIndex1 The reserved first index of global item
     * @return globalIndex2 The reserved second index of global item
     */
    function reserveGlobalItemSlot(
        uint index1,
        uint index2
    )
    external pure
    returns (
        uint globalIndex1,
        uint globalIndex2
    ) {
        // Increment global Item, this starts from 0, 0
        globalIndex1 = index1;
        globalIndex2 = index2;
        
        if ((globalIndex2 + 1) == 0) {
            // This is loopback, Increment newIndex1
            globalIndex1 = globalIndex1.add(1);
            globalIndex2 = 0;
        }
        else {
             globalIndex2 = globalIndex2 + 1;
        }
    }

    /**
     * @dev Function to add item to global items
     * @param self is the entire mapping of globalItems
     * @param _index1 is the first index of the item in relation to globalItems variable
     * @param _index2 is the second index of the item in relation to globalItems variable
     * @param _ownerEIN is the EIN of the user
     * @param _itemIndex is the index at which the item exists on the user mapping
     * @param _isFile indicates if the item is a File or a Group
     * @param _isHidden indicates if the item has been hidden
     * @param _stampingInitiated indicates if the item has been stamped or not
     */
    function addItemToGlobalItems(
        mapping (uint => mapping(uint => Association)) storage self, 
        uint _index1, 
        uint _index2, 
        uint _ownerEIN, 
        uint _itemIndex, 
        bool _isFile, 
        bool _isHidden, 
        uint32 _stampingInitiated
    )
    external {
        // Add item to global item, no stiching it
        self[_index1][_index2] = Association (
            ItemOwner (
                _ownerEIN, // Owner EIN
                _itemIndex // Item stored at what index for that EIN
            ),
            
            ItemOwner ( // This is to store stamping info for recipient
                0, // recipient EIN, defaults to 0
                0 // timestamp, defaults to 0
            ),
            
            _isFile, // Item is file or group
            _isHidden, // whether stamping is initiated or not
            false, // Item is deleted or still exists

            _stampingInitiated, // whether file is stamped or not
            0, // whether stamping is completed by recipient, defaults to 0
            false, // whether stamping is rejected by recipient, defaults to false
            
            0 // the count of shared EINs
        );
    }

    /**
     * @dev Function to delete a global items
     * @param self is the Association Struct (IceGlobal library) of the item
     */
    function deleteGlobalRecord(Association storage self)
    external {
        self.deleted = true;
    }
    
    /**
     * @dev Function to get the transfer history of EINs
     * @param self is the mapping of ItemOwner to users, useful in keeping a history of transfers
     * @param _transferCount is the total transfers done for a particular file 
     * 
     */
    function getHistoralEINsForGlobalItems(
        mapping (uint8 => ItemOwner) storage self, 
        uint8 _transferCount
    ) 
    external view 
    returns (uint[] memory EINs){
        uint8 i = 0;
        uint8 tc = _transferCount;
        
        while (tc != 0) {
            EINs[i] = self[tc].EIN;
            
            i = i.add(1);
            tc = tc.sub(1);
        }
    }
    
    /**
     * @dev Function to find the relevant mapping index of item mapped for a given EIN
     * @param self is the mapping of ItemOwner to users
     * @param _count is the count of relative mapping of global item Association
     * @param _searchForEIN is the non-owner EIN to search
     * @return mappedIndex is the index which is where the relative mapping points to for those items
     * @return ownerFound indicates if the owner was found or not
     */
    function findItemOwnerInGlobalItems(
        mapping (uint8 => ItemOwner) storage self, 
        uint8 _count, 
        uint256 _searchForEIN
    ) 
    external view 
    returns (
        uint8 mappedIndex,
        bool ownerFound
    ) {
        // Logic
        mappedIndex = 0;
        uint8 count = _count;
        
        while (count > 0) {
            if (self[count].EIN == _searchForEIN) {
                mappedIndex = count;
                ownerFound = true;
                
                count = 1;
            }
            
            count = count.sub(1);
        }
    }
    
    /**
     * @dev Function to add items to the global items mapping
     * @param self is the Association Struct (IceGlobal library) which contains item properties
     * @param _ofType is the associative property type (shared or stamped)
     * @param _toEIN is the non-owner id 
     * @param _itemIndex is the index of the item for the non-owner id
     * @return newCount is the new count of the associative property
     */
    function addToGlobalItemsMapping(
        Association storage self, 
        uint8 _ofType, 
        uint _toEIN, 
        uint _itemIndex
    )
    external
    returns (uint8 newCount) {
        // Logic
        uint8 currentCount;
        
        // Allocalte based on type.
        if (_ofType == uint8(AsscProp.sharedTo)) {
            currentCount = self.sharedToCount;
        }
        else if (_ofType == uint8(AsscProp.stampedTo)) {
            currentCount = self.sharedToCount;
        }
        
        newCount = currentCount.add(1);
            
        if (_ofType == uint8(AsscProp.sharedTo)) {
            // Logic
            ItemOwner memory mappedItem = ItemOwner (
                _toEIN,
                _itemIndex
            );
            
            self.sharedTo[newCount] = mappedItem;
            self.sharedToCount = newCount;
            
            // Add the EIN which is getting shared
            self.sharedToEINMapping[_toEIN] = true;
        }
        else if (_ofType == uint8(AsscProp.stampedTo)) {
            // Logic
            self.stampingRecipient = ItemOwner (
                _toEIN,
                _itemIndex
            );
        }
    }

    /**
     * @dev Private Function to remove from global items mapping
     * @param self is the Association Struct (IceGlobal library) which contains item properties     
     * @param _ofType is the associative property type (shared or stamped)
     * @param _mappedIndex is the non-owner mapping of stored item 
     * @return newCount is the new count of the associative property
     */
    function removeFromGlobalItemsMapping(
        Association storage self, 
        uint8 _ofType, 
        uint8 _mappedIndex
    )
    external
    returns (uint8 newCount) {
        // Logic
        
        // Just swap and deduct
        if (_ofType == uint8(AsscProp.sharedTo)) {
            newCount = self.sharedToCount.sub(1);
            
            // Remove the EIN which is getting unshared
            self.sharedToEINMapping[self.sharedTo[_mappedIndex].EIN] = false;
            
            // Logic Operation
            self.sharedTo[_mappedIndex] = self.sharedTo[self.sharedToCount];
            self.sharedToCount = newCount;
        }
        else if (_ofType == uint8(AsscProp.stampedTo)) {
            self.stampingRecipient = ItemOwner (
                0, // recipient EIN, defaults to 0
                0 // index, defaults to 0
            );
        }
    }
    
    /**
     * @dev Private Function to check that only unique EINs can have access
     * @param _ein is the EIN of the user
     * @param _identityRegistry is the IdentityRegistry pointer (ERC-1484)
     */
    function condEINExists(
        uint _ein,
        IdentityRegistryInterface _identityRegistry
    )
    external view {
        require (
            (_identityRegistry.identityExists(_ein) == true),
            "EIN not Found"
        );
    }

    /**
     * @dev Private Function to check that only unique EINs can have access
     * @param _ein1 The First EIN
     * @param _ein2 The Second EIN
     */
    function condValidEIN(
        uint _ein1, 
        uint _ein2
    )
    external pure {
        require (
            (_ein1 != _ein2),
            "Same EINs"
        );
    }
    
    /**
     * @dev Private Function to check that only unique EINs can have access
     * @param _ein1 The First EIN
     * @param _ein2 The Second EIN
     */
    function condUniqueEIN(
        uint _ein1, 
        uint _ein2
    )
    external pure {
        require (
            (_ein1 != _ein2),
            "Same EINs"
        );
    }
    
    /**
     * @dev Function to check that only owner of EIN can access this
     * @param self is the Association Struct (IceGlobal library) which contains item properties
     * @param _ein is the EIN of the item owner
     */
    function condItemOwner(
        Association storage self, 
        uint _ein
    )
    external view {
        require (
            (self.ownerInfo.EIN == _ein),
            "Only File Owner"
        );
    }
    
    /**
     * @dev Function to check that a item hasn't been marked for stamping
     * @param self is the Association Struct (IceGlobal library) which contains item properties
     */
    function condUnstampedItem(Association storage self)
    external view {
        // Check if the item is stamped or not
        require (
            (self.stampingInitiated == 0),
            "Item Stamping Initiated"
        );
    }
    
    /**
     * @dev Function to check that a item has been marked for stamping
     * @param self is the Association Struct (IceGlobal library) which contains item properties
     */
    function condStampedItem(Association storage self)
    external view {
        // Check if the item stamping is Initiated
        require (
            (self.stampingInitiated != 0),
            "Item Stamping Not Initiated"
        );
    }
    
    /**
     * @dev Function to check that a item is only marked by stamping from owner
     * @param self is the Association Struct (IceGlobal library) which contains item properties
     */
    function condUncompleteStamping(Association storage self)
    external view {
        // Check if the item is stamped or not
        require (
            (self.stampingCompleted == 0),
            "Item Stamping is Completed"
        );
    }
    
    /**
     * @dev Function to check that an item is file or not
     * @param self is the Association Struct (IceGlobal library) which contains item properties
     */
    function condItemIsFile(Association storage self)
    external view {
        // Check if the item is File
        require (
            (self.isFile == true),
            "Item is not File"
        );
    }
    
    /**
     * @dev Function to check if an item exists
     * @param _itemIndex the index of the item
     * @param _itemCount is the count of that mapping
     */
    function condValidItem(
        uint _itemIndex, 
        uint _itemCount
    )
    public pure {
        require (
            (_itemIndex <= _itemCount),
            "Item Not Found"
        );
    }
    
    /**
     * @dev Function to check that overflow doesn't occur
     * @param index is the current index which needs to be checked
     */
    function condCheckOverflow(uint index) 
    external pure { 
        require (
            (index + 1 > index),
            "Limit Reached - Overflow"
        );
    }
    
    /**
     * @dev Function to check that Underflow doesn't occur
     * @param index is the current index which needs to be checked
     */
    function condCheckUnderflow(uint index) 
    external pure { 
        require (
            (index - 1 < index),
            "Limit Reached - Underflow"
        );
    }
     
    // 2. WHITE / BLACK LIST
    /**
     * @dev Function to check if user is in a particular list (blacklist or whitelist) of the primary user
     * @param self is the mapping of entire whitelist / blacklist of the primary user
     * @param _forEIN is the ein of the recipient
     */
    function isUserInList(
        mapping(uint => bool) storage self, 
        uint _forEIN
    ) 
    external view 
    returns (bool) {
        return self[_forEIN];
    }
    
    /**
     * @dev Function to add a user who is not the owner of the item to whitelist of the primary user
     * @param self is the mapping of entire whitelist of the primary user
     * @param _targetEIN is the ein of the target user
     * @param _blacklist is the maping entire blacklist of the primary user
     */
    function addToWhitelist(
        mapping(uint => bool) storage self, 
        uint _targetEIN, 
        mapping(uint => bool) storage _blacklist
    )
    external {
        // Check Restrictions
        condNotInList(_blacklist, _targetEIN);

        // Logic
        self[_targetEIN] = true;
    }

    /**
     * @dev Function to remove a user who is not the owner of the item to whitelist of the primary user
     * @param self is the mapping of entire whitelist of the primary user
     * @param _targetEIN is the ein of the target user
     * @param _blacklist is the maping entire blacklist of the primary user
     */
    function removeFromWhitelist(
        mapping(uint => bool) storage self, 
        uint _targetEIN, 
        mapping(uint => bool) storage _blacklist
    )
    external {
        // Check Restrictions
        condNotInList(_blacklist, _targetEIN);

        // Logic
        self[_targetEIN] = false;
    }

    /**
     * @dev Function to add a user who is not the owner of the item to blacklist
     * @param self is the mapping of entire blacklist of the primary user
     * @param _targetEIN is the ein of the target user
     * @param _whitelist is the maping entire whitelist of the primary user
     */
    function addToBlacklist(
        mapping(uint => bool) storage self, 
        uint _targetEIN, 
        mapping(uint => bool) storage _whitelist
    )
    external {
        // Check Restrictions
        condNotInList(_whitelist, _targetEIN);

        // Logic
        self[_targetEIN] = true;
    }

    /**
     * @dev Function to remove a user who is not the owner of the item from blacklist
     * @param self is the mapping of entire blacklist of the primary user
     * @param _targetEIN is the ein of the target user
     * @param _whitelist is the mapiing entire whitelist of the primary user
     */
    function removeFromBlacklist(
        mapping(uint => bool) storage self, 
        uint _targetEIN, 
        mapping(uint => bool) storage _whitelist
    )
    external {
        // Check Restrictions
        condNotInList(_whitelist, _targetEIN);

        // Logic
        self[_targetEIN] = false;
    }
    
    /**
     * @dev Function to check if the user is not in a list (blacklist or whitelist) of primary user
     * @param self is the mapping of entire whitelist or blacklist of the primary user
     * @param _targetEIN is the EIN of the user who is getting checked
     */
    function condNotInList(
        mapping (uint => bool) storage self, 
        uint _targetEIN
    )
    public view {
        require (
            (self[_targetEIN] == false),
            "EIN in blacklist / whitelist"
        );
    }
}