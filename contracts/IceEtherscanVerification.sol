/**
 *Submitted for verification at Etherscan.io on 2nd October 2019
*/

pragma solidity ^0.5.1;

interface SnowflakeInterface {
    function deposits(uint) external view returns (uint);
    function resolverAllowances(uint, address) external view returns (uint);

    function identityRegistryAddress() external returns (address);
    function hydroTokenAddress() external returns (address);
    function clientRaindropAddress() external returns (address);

    function setAddresses(address _identityRegistryAddress, address _hydroTokenAddress) external;
    function setClientRaindropAddress(address _clientRaindropAddress) external;

    function createIdentityDelegated(
        address recoveryAddress, address associatedAddress, address[] calldata providers, string calldata casedHydroId,
        uint8 v, bytes32 r, bytes32 s, uint timestamp
    ) external returns (uint ein);
    function addProvidersFor(
        address approvingAddress, address[] calldata providers, uint8 v, bytes32 r, bytes32 s, uint timestamp
    ) external;
    function removeProvidersFor(
        address approvingAddress, address[] calldata providers, uint8 v, bytes32 r, bytes32 s, uint timestamp
    ) external;
    function upgradeProvidersFor(
        address approvingAddress, address[] calldata newProviders, address[] calldata oldProviders,
        uint8[2] calldata v, bytes32[2] calldata r, bytes32[2] calldata s, uint[2] calldata timestamp
    ) external;
    function addResolver(address resolver, bool isSnowflake, uint withdrawAllowance, bytes calldata extraData) external;
    function addResolverAsProvider(
        uint ein, address resolver, bool isSnowflake, uint withdrawAllowance, bytes calldata extraData
    ) external;
    function addResolverFor(
        address approvingAddress, address resolver, bool isSnowflake, uint withdrawAllowance, bytes calldata extraData,
        uint8 v, bytes32 r, bytes32 s, uint timestamp
    ) external;
    function changeResolverAllowances(address[] calldata resolvers, uint[] calldata withdrawAllowances) external;
    function changeResolverAllowancesDelegated(
        address approvingAddress, address[] calldata resolvers, uint[] calldata withdrawAllowances,
        uint8 v, bytes32 r, bytes32 s
    ) external;
    function removeResolver(address resolver, bool isSnowflake, bytes calldata extraData) external;
    function removeResolverFor(
        address approvingAddress, address resolver, bool isSnowflake, bytes calldata extraData,
        uint8 v, bytes32 r, bytes32 s, uint timestamp
    ) external;

    function triggerRecoveryAddressChangeFor(
        address approvingAddress, address newRecoveryAddress, uint8 v, bytes32 r, bytes32 s
    ) external;

    function transferSnowflakeBalance(uint einTo, uint amount) external;
    function withdrawSnowflakeBalance(address to, uint amount) external;
    function transferSnowflakeBalanceFrom(uint einFrom, uint einTo, uint amount) external;
    function withdrawSnowflakeBalanceFrom(uint einFrom, address to, uint amount) external;
    function transferSnowflakeBalanceFromVia(uint einFrom, address via, uint einTo, uint amount, bytes calldata _bytes)
        external;
    function withdrawSnowflakeBalanceFromVia(uint einFrom, address via, address to, uint amount, bytes calldata _bytes)
        external;
}

interface IdentityRegistryInterface {
    function isSigned(address _address, bytes32 messageHash, uint8 v, bytes32 r, bytes32 s)
        external pure returns (bool);

    // Identity View Functions /////////////////////////////////////////////////////////////////////////////////////////
    function identityExists(uint ein) external view returns (bool);
    function hasIdentity(address _address) external view returns (bool);
    function getEIN(address _address) external view returns (uint ein);
    function isAssociatedAddressFor(uint ein, address _address) external view returns (bool);
    function isProviderFor(uint ein, address provider) external view returns (bool);
    function isResolverFor(uint ein, address resolver) external view returns (bool);
    function getIdentity(uint ein) external view returns (
        address recoveryAddress,
        address[] memory associatedAddresses, address[] memory providers, address[] memory resolvers
    );

    // Identity Management Functions ///////////////////////////////////////////////////////////////////////////////////
    function createIdentity(address recoveryAddress, address[] calldata providers, address[] calldata resolvers)
        external returns (uint ein);
    function createIdentityDelegated(
        address recoveryAddress, address associatedAddress, address[] calldata providers, address[] calldata resolvers,
        uint8 v, bytes32 r, bytes32 s, uint timestamp
    ) external returns (uint ein);
    function addAssociatedAddress(
        address approvingAddress, address addressToAdd, uint8 v, bytes32 r, bytes32 s, uint timestamp
    ) external;
    function addAssociatedAddressDelegated(
        address approvingAddress, address addressToAdd,
        uint8[2] calldata v, bytes32[2] calldata r, bytes32[2] calldata s, uint[2] calldata timestamp
    ) external;
    function removeAssociatedAddress() external;
    function removeAssociatedAddressDelegated(address addressToRemove, uint8 v, bytes32 r, bytes32 s, uint timestamp)
        external;
    function addProviders(address[] calldata providers) external;
    function addProvidersFor(uint ein, address[] calldata providers) external;
    function removeProviders(address[] calldata providers) external;
    function removeProvidersFor(uint ein, address[] calldata providers) external;
    function addResolvers(address[] calldata resolvers) external;
    function addResolversFor(uint ein, address[] calldata resolvers) external;
    function removeResolvers(address[] calldata resolvers) external;
    function removeResolversFor(uint ein, address[] calldata resolvers) external;

    // Recovery Management Functions ///////////////////////////////////////////////////////////////////////////////////
    function triggerRecoveryAddressChange(address newRecoveryAddress) external;
    function triggerRecoveryAddressChangeFor(uint ein, address newRecoveryAddress) external;
    function triggerRecovery(uint ein, address newAssociatedAddress, uint8 v, bytes32 r, bytes32 s, uint timestamp)
        external;
    function triggerDestruction(
        uint ein, address[] calldata firstChunk, address[] calldata lastChunk, bool resetResolvers
    ) external;
}

/**
* @title SafeMath
* @dev Math operations with safety checks that revert on error
*/
library SafeMath {

    /**
    * @dev Multiplies two numbers, reverts on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
    * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0); // Solidity only automatically asserts when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
    * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
    * @dev Adds two numbers, reverts on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
    * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

/**
* @title SafeMath8
* @dev Math operations with safety checks that revert on error
*/
library SafeMath8 {

    /**
    * @dev Multiplies two numbers, reverts on overflow.
    */
    function mul(uint8 a, uint8 b) internal pure returns (uint8) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint8 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
    * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
    */
    function div(uint8 a, uint8 b) internal pure returns (uint8) {
        require(b > 0); // Solidity only automatically asserts when dividing by 0
        uint8 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
    * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint8 a, uint8 b) internal pure returns (uint8) {
        require(b <= a);
        uint8 c = a - b;

        return c;
    }

    /**
    * @dev Adds two numbers, reverts on overflow.
    */
    function add(uint8 a, uint8 b) internal pure returns (uint8) {
        uint8 c = a + b;
        require(c >= a);

        return c;
    }

    /**
    * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint8 a, uint8 b) internal pure returns (uint8) {
        require(b != 0);
        return a % b;
    }
}

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

/**
 * @title Ice Protocol Sort Libray
 * @author Harsh Rajat
 * @notice Create sorting order for maximizing space utilization
 * @dev This Library is part of many that Ice uses form a robust File Management System
 */
library IceSort {
     using SafeMath for uint;
     
    /* ***************
    * DEFINE STRUCTURES
    *************** */
    /* To define the order required to have double linked list */
    struct SortOrder {
        uint next; // the next ID of the order
        uint prev; // the prev ID of the order

        uint pointerID; // what it should point to in the mapping

        bool active; // whether the node is active or not
    }
    
    /* ***************
    * DEFINE FUNCTIONS
    *************** */
    // 1. SORTING LIBRARY
    /**
     * @dev Function to facilitate returning of double linked list used
     * @param self is the relevant mapping of SortOrder Struct (IceSort Library) for Files, Groups, Transfers, etc
     * @param _seedPointer is the pointer (index) of the order mapping
     * @return prev is the previous index in the sort order mapping 
     * @return next is the next index in the sort order mapping
     * @return pointerID is the pointer index which the sort order is pointing to
     * @return active shows whether that particular sort order mapping is active or not
     */
    function getOrder(
        mapping(uint => SortOrder) storage self, 
        uint _seedPointer
    )
    public view
    returns (uint prev, uint next, uint pointerID, bool active) {
        prev = self[_seedPointer].prev;
        next = self[_seedPointer].next;
        pointerID = self[_seedPointer].pointerID;
        active = self[_seedPointer].active;
    }

    /**
     * @dev Function to facilitate adding of double linked list used to preserve order and form cicular linked list
     * @param self is the relevant mapping of SortOrder Struct (IceSort Library) for Files, Groups, Transfers, etc
     * @param _currentIndex is the index which is at the last of the queue
     * @param _maxIndex is the highest index present
     * @param _pointerID is the ID to which it should point to, pass 0 to calculate on existing logic flow
     * @return nextIndex is the count of the specific sort order mapping
     */
    function addToSortOrder(
        mapping(uint => SortOrder) storage self, 
        uint _currentIndex,
        uint _maxIndex,
        uint _pointerID
    )
    external
    returns (uint nextIndex) {
        // Next Index is always +1
        nextIndex = _maxIndex.add(1);

        // Assign current order to next pointer
        self[_currentIndex].next = nextIndex;
        self[_currentIndex].active = true;

        // Special case of root of sort order
        if (_maxIndex == 0) {
            self[0].next = nextIndex;
        }

        // Assign initial group prev order
        self[0].prev = nextIndex;

        // Whether This is assigned or calculated
        uint pointerID;
        if (_pointerID == 0) {
            pointerID = nextIndex;
        }
        else {
            pointerID = _pointerID;
        }

        // Assign next group order pointer and prev pointer
        self[nextIndex] = SortOrder(
            0, // next index
            _currentIndex, // prev index
            pointerID, // pointerID
            true // mark as active
        );
    }

    /**
     * @dev Function to facilitate stiching of double linked list used to preserve order with delete
     * @param self is the relevant mapping of SortOrder Struct (IceSort Library) for Files, Groups, Transfers, etc
     * @param _remappedIndex is the index which is swapped to from the latest index
     * @param _maxIndex is the index which will always be maximum
     * @param _pointerID is the ID to which it should point to, pass 0 to calculate on existing logic flow
     * @return prevIndex is the count of the specific sort order mapping
     */
    function stichSortOrder(
        mapping(uint => SortOrder) storage self, 
        uint _remappedIndex, 
        uint _maxIndex, 
        uint _pointerID
    )
    external
    returns (uint prevIndex){
        // Stich Order
        uint prevGroupIndex = self[_remappedIndex].prev;
        uint nextGroupIndex = self[_remappedIndex].next;

        self[prevGroupIndex].next = nextGroupIndex;
        self[nextGroupIndex].prev = prevGroupIndex;

        // Check if this is not the top order number
        if (_remappedIndex != _maxIndex) {
            // Change order mapping and remap
            self[_remappedIndex] = self[_maxIndex];
            if (_pointerID == 0) {
                self[_remappedIndex].pointerID = _remappedIndex;
            }
            else {
                self[_remappedIndex].pointerID = _pointerID;
            }
            self[self[_remappedIndex].next].prev = _remappedIndex;
            self[self[_remappedIndex].prev].next = _remappedIndex;
        }

        // Turn off the non-stich group
        self[_maxIndex].active = false;

        // Decrement count index if it's non-zero
        prevIndex = _maxIndex.sub(1);
    }
    
    // *. REFERENTIAL INDEXES FUNCTIONS
    /**
     * @dev Private Function to return maximum 20 Indexes of Files, Groups, Transfers,
     * etc based on their SortOrder. 0 is always reserved but will point to Root in Group & Avatar in Files
     * @param self is the relevant mapping of SortOrder Struct (IceSort Library) for Files, Groups, Transfers, etc
     * @param _seedPointer is the pointer (index) of the order mapping
     * @param _limit is the number of files requested | Maximum of 20 can be retrieved
     * @param _asc is the order, i.e. Ascending or Descending
     * @return sortedIndexes is the indexes returned for Files, Groups, Transfers, etc
     */
    function getIndexes(
        mapping(uint => SortOrder) storage self, 
        uint _seedPointer, 
        uint16 _limit, 
        bool _asc
    )
    external view
    returns (uint[20] memory sortedIndexes) {
        uint next;
        uint prev;
        uint pointerID;
        bool active;
        
        uint limit = _limit;
        
        // Get initial Order
        (prev, next, pointerID, active) = getOrder(self, _seedPointer);

        // Get Previous or Next Order | Round Robin Fashion
        if (_asc == true) {
            // Ascending Order
            (prev, next, pointerID, active) = getOrder(self, next);
        }
        else {
            // Descending Order
            (prev, next, pointerID, active) = getOrder(self, prev);
        }

        uint16 i = 0;

        if (limit >= 20) {
            limit = 20; // always account for root
        }

        while (limit != 0) {

            if (active == false || pointerID == 0) {
                limit = 0;

                if (pointerID == 0) {
                    //add root as Special case
                    sortedIndexes[i] = 0;
                }
            }
            else {
                // Get PointerID
                sortedIndexes[i] = pointerID;

                // Get Previous or Next Order | Round Robin Fashion
                if (_asc == true) {
                    // Ascending Order
                    (prev, next, pointerID, active) = getOrder(self, next);
                }
                else {
                    // Descending Order
                    (prev, next, pointerID, active) = getOrder(self, prev);
                }

                // Increment counter
                i++;

                // Decrease Limit
                limit--;
            }
        }
    }
    
    /**
     * @dev Function to check that Group Order is valid
     * @param self is the specific SortOrder Struct (IceSort Library)
     * @param _groupOrderIndex The index of the group order
     */
    function condValidSortOrder(
        SortOrder storage self, 
        uint _groupOrderIndex
    )
    public view {
        require (
            (_groupOrderIndex == 0 || self.active == true),
            "Group Order not Found"
        );
    }
}

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

/**
 * @title Ice Protocol Files / Groups / Users Meta Management System Libray
 * @author Harsh Rajat
 * @notice Create sorting order for maximizing space utilization
 * @dev This Library is part of many that Ice uses form a robust File Management System
 */
library IceFMS {
    using SafeMath for uint;
    using SafeMath8 for uint8;
    
    using IceGlobal for IceGlobal.GlobalRecord;
    using IceGlobal for IceGlobal.Association;
    using IceGlobal for IceGlobal.UserMeta;
    using IceGlobal for mapping (uint => bool);
    using IceGlobal for mapping (uint8 => IceGlobal.ItemOwner);
    using IceGlobal for mapping (uint => mapping (uint => IceGlobal.Association));
    using IceGlobal for uint;
    
    using IceSort for mapping (uint => IceSort.SortOrder);
    using IceSort for IceSort.SortOrder;
    
    using IceFMSAdv for mapping (uint => mapping(uint => IceGlobal.GlobalRecord));
    
    
    /* ***************
    * DEFINE STRUCTURES
    *************** */
    /* To define the multihash function for storing of hash */
    struct FileMeta {
        bytes32 name; // to store the name of the file
        
        bytes32 hash; // to store the hash of file
        bytes22 hashExtraInfo; // to store any extra info if required
        
        bool encrypted; // whether the file is encrypted
        bool markedForTransfer; // Mark the file as transferred
        
        uint8 protocol; // store protocol of the file stored | 0 is URL, 1 is IPFS
        uint8 transferCount; // To maintain the transfer count for mapping
        
        uint8 hashFunction; // Store the hash of the file for verification | 0x000 for deleted files
        uint8 hashSize; // Store the length of the digest
        
        uint32 timestamp;  // to store the timestamp of the block when file is created
    }
    
    /* To define File structure of all stored files */
    struct File {
        // File Meta Data
        IceGlobal.GlobalRecord rec; // store the association in global record

        // File Properties
        bytes protocolMeta; // store metadata of the protocol
        FileMeta fileMeta; // store metadata associated with file

        // File Properties - Encryption Properties
        mapping (address => bytes32) encryptedHash; // Maps Individual address to the stored hash

        // File Other Properties
        uint associatedGroupIndex; // to store the group index of the group that holds the file
        uint associatedGroupFileIndex; // to store the mapping of file in the specific group order
        uint transferEIN; // To record EIN of the user to whom trasnfer is inititated
        uint transferIndex; // To record the transfer specific index of the transferee

        // File Transfer Properties
        mapping (uint => uint) transferHistory; // To maintain histroy of transfer of all EIN
    }

    /* To connect Files in linear grouping,
     * sort of like a folder, 0 or default grooupID is root
     */
    struct Group {
        IceGlobal.GlobalRecord rec; // store the association in global record

        string name; // the name of the Group

        mapping (uint => IceSort.SortOrder) groupFilesOrder; // the order of files in the current group
        uint groupFilesCount; // To keep the count of group files
    }
     
    /* ***************
    * DEFINE FUNCTIONS
    *************** */
    // 1. FILE FUNCTIONS
    /**
     * @dev Function to get file info of an EIN
     * @param self is the pointer to the File Struct (IceFMS Library) passed
     * @return protocol returns the protocol used for storage of the file (0 - URL, 1 - IPFS)
     * @return protocolMeta returns the meta info associated with a protocol
     * @return fileName is the name of the file
     * @return fileHash is the Hash of the file
     * @return hashExtraInfo is extra info stored as part of the protocol used 
     * @return hashFunction is the function used to store that hash
     * @return hashSize is the size of the digest
     * @return encryptedStatus indicates if the file is encrypted or not 
     */
    function getFileInfo(File storage self)
    external view
    returns (
        uint8 protocol, 
        bytes memory protocolMeta, 
        string memory fileName, 
        bytes32 fileHash, 
        bytes22 hashExtraInfo,
        uint8 hashFunction,
        uint8 hashSize,
        bool encryptedStatus
    ) {
        // Logic
        protocol = self.fileMeta.protocol; // Protocol
        protocolMeta = self.protocolMeta; // Protocol meta
        
        fileName = bytes32ToString(self.fileMeta.name); // File Name, convert from byte32 to string
        
        fileHash = self.fileMeta.hash; // hash of the file
        hashExtraInfo = self.fileMeta.hashExtraInfo; // extra info of hash of the file (to utilize 22 bytes of wasted space)
        hashFunction = self.fileMeta.hashFunction; // the hash function used to store the file
        hashSize = self.fileMeta.hashSize; // The length of the digest
        
        encryptedStatus = self.fileMeta.encrypted; // Whether the file is encrypted or not
    }
    
    /**
     * @dev Function to get file info of an EIN
     * @param self is the pointer to the File Struct (IceFMS Library) passed
     * @return timestamp indicates the timestamp of the file
     * @return associatedGroupIndex indicates the group which the file is associated to in the user's FMS
     * @return associatedGroupFileIndex indicates the file index within the group of the user's FMS
     */
    function getFileOtherInfo(File storage self)
    external view
    returns (
        uint32 timestamp, 
        uint associatedGroupIndex, 
        uint associatedGroupFileIndex
    ) {
        // Logic
        timestamp = self.fileMeta.timestamp;
        associatedGroupIndex = self.associatedGroupIndex;
        associatedGroupFileIndex = self.associatedGroupFileIndex;
    }

    /**
     * @dev Function to get file tranfer info of an EIN
     * @param self is the pointer to the File Struct (IceFMS Library) passed
     * @return transferCount indicates the number of times the file has been transferred
     * @return transferEIN indicates the EIN of the user to which the file is currently scheduled for transfer
     * @return transferIndex indicates the transfer index of the target EIN where the file is currently mapped to
     * @return markedForTransfer indicates if the file is marked for transfer or not
     */
    function getFileTransferInfo(File storage self)
    external view
    returns (
        uint transferCount, 
        uint transferEIN, 
        uint transferIndex, 
        bool markedForTransfer
    ) {
        // Logic
        transferCount = self.fileMeta.transferCount; 
        transferEIN = self.transferEIN; 
        transferIndex = self.transferIndex; 
        markedForTransfer = self.fileMeta.markedForTransfer;
    }

    /**
     * @dev Function to get file tranfer owner info of an EIN
     * @param self is the pointer to the File Struct (IceFMS Library) passed
     * @param _transferIndex is index to poll which is useful to get the history of transfers and to what EIN the file previously belonged to
     * @return previousOwnerEIN is the EIN of the user who had originally owned that file
     */
    function getFileTransferOwners(
        File storage self, 
        uint _transferIndex
    )
    external view
    returns (uint previousOwnerEIN) {
        previousOwnerEIN = self.transferHistory[_transferIndex];    // Return transfer history associated with a particular transfer index
    }
    
    /**
     * @dev Function to create a basic File Object for a given file
     * @param self is the pointer to the File Struct (IceFMS Library) passed
     * @param _protocolMeta is the meta info which is stored for a certain protocol
     * @return _groupIndex is the index of the group where the file is stored
     * @return _groupFilesCount is the number of files stored in that group 
     */
    function createFileObject(
        File storage self,
        bytes calldata _protocolMeta,
        uint _groupIndex, 
        uint _groupFilesCount
    )
    external {
        // Set other File info
        self.protocolMeta = _protocolMeta;
        
        self.associatedGroupIndex = _groupIndex;
        self.associatedGroupFileIndex = _groupFilesCount;
    }
    
    /**
     * @dev Function to create a File Meta Object and attach it to File Struct (IceFMS Library)
     * @param self is the pointer to the File Struct (IceFMS Library) passed
     * @param _protocol is type of protocol used to store that file (0 - URL, 1- IPFS)
     * @param _name is the name of the file with the extension
     * @param _hash is the hash of the file (useful for IPFS and to verify authenticity)
     * @param _hashExtraInfo is the extra info which can be stored in a 22 byte format (if required)
     * @param _hashFunction is the function used to generate the hash
     * @param _hashSize is the size of the digest
     * @param _encrypted indicates if the file is encrypted or not  
     */
    function createFileMetaObject(
        File storage self,
        uint8 _protocol,
        bytes32 _name, 
        bytes32 _hash,
        bytes22 _hashExtraInfo,
        uint8 _hashFunction,
        uint8 _hashSize,
        bool _encrypted
    )
    external {
        //set file meta
        self.fileMeta = FileMeta(
            _name,                  // to store the name of the file
            
            _hash,                  // to store the hash of file
            _hashExtraInfo,         // to store any extra info if required
            
            _encrypted,             // whether the file is encrypted
            false,                  // Mark the file as transferred, defaults to false
                
            _protocol,              // store protocol of the file stored | 0 is URL, 1 is IPFS
            1,                      // Default transfer count is 1
            
            _hashFunction,          // Store the hash of the file for verification | 0x000 for deleted files
            _hashSize,              // Store the length of the digest
            
            uint32(now)             // to store the timestamp of the block when file is created
        );
    }
    
    /**
     * @dev Function to write file to a user FMS
     * @param self is the pointer to the File Struct (IceFMS Library) passed
     * @param group is the pointer to the group where the file is going to be stored for the primary user (EIN)
     * @param _groupIndex indicates the index of the group for the EIN's FMS
     * @param _userFileOrderMapping is the mapping of the user's file order using SortOrder Struct (IceSort Library)
     * @param _maxFileIndex indicates the maximum index of the files stored for the primary user (EIN)
     * @param _nextIndex indicates the next index which will store the particular file in question
     * @param _transferEin is the EIN of the user for which the file is getting written to, defaults to primary user
     * @param _encryptedHash is the encrypted hash stored incase the file is encrypted
     */
    function writeFile(
        File storage self, 
        Group storage group, 
        uint _groupIndex, 
        mapping(uint => IceSort.SortOrder) storage _userFileOrderMapping, 
        uint _maxFileIndex, 
        uint _nextIndex, 
        uint _transferEin, 
        bytes32 _encryptedHash
    ) 
    external 
    returns (uint newFileCount) {
        // Add file to group 
        (self.associatedGroupIndex, self.associatedGroupFileIndex) = addFileToGroup(group, _groupIndex, _nextIndex);
        
        // To map encrypted password
        self.encryptedHash[msg.sender] = _encryptedHash;

        // To map transfer history
        self.transferHistory[0] = _transferEin;

        // Add to Stitch Order & Increment index
        newFileCount = _userFileOrderMapping.addToSortOrder(_userFileOrderMapping[0].prev, _maxFileIndex, 0);
    }
    
    /**
     * @dev Function to move file to another group
     * @param self is the pointer to the File Struct (IceFMS Library) passed
     * @param _fileIndex is the file index in the user's FMS files mapping
     * @param _groupMapping is the mapping of all groups for the user's FMS
     * @param _groupOrderMapping is the mapping of the order of files in that group for the primary user's FMS
     * @param _newGroupIndex is the index of the new group where file has to be moved
     * @param _globalItems is the mapping of all items stored by all users in the Ice FMS
     * @return groupFileIndex is the index of the file stored in that relevant group of the primary user 
     */
    function moveFileToGroup(
        File storage self, 
        uint _fileIndex,
        mapping(uint => IceFMS.Group) storage _groupMapping, 
        mapping(uint => IceSort.SortOrder) storage _groupOrderMapping,
        uint _newGroupIndex,
        mapping (uint => mapping(uint => IceGlobal.Association)) storage _globalItems
    )
    external 
    returns (uint groupFileIndex){
        // Check Restrictions
        _groupOrderMapping[_newGroupIndex].condValidSortOrder(_newGroupIndex); // Check if the new group is valid
        self.rec.getGlobalItemViaRecord(_globalItems).condUnstampedItem(); // Check if the file is unstamped, can't move a stamped file
        
        // Check if the current group is unstamped, can't move a file from stamped group
        _groupMapping[self.associatedGroupIndex].rec.getGlobalItemViaRecord(_globalItems).condUnstampedItem(); 
        
        // Check if the new group is unstamped, can't move a file from stamped group
        _groupMapping[_newGroupIndex].rec.getGlobalItemViaRecord(_globalItems).condUnstampedItem(); 
        
        // remap the file
        groupFileIndex = remapFileToGroup(
            self, 
            _fileIndex,
            _groupMapping[self.associatedGroupIndex], 
            _groupMapping[_newGroupIndex], 
            _newGroupIndex
        );
    }

    /**
     * @dev Function to delete file of the owner
     * @param self is the mapping of all pointer to the File Struct (IceFMS Library) passed for a user's FMS
     * @param _ein is the EIN of the primary user
     * @param _fileIndex is the index where file is stored
     * @param _globalItemIndividual is the Association Struct (IceGlobal Library) that contains additional info about file
     * @param _fileOrderMapping is the mapping of the files of the primary user's FMS
     * @param _fileCountMapping is the mapping of the file count of all the users
     * @param _fileGroup is the Group Struct (IceFMS Library) under which the file in question is stored
     * @param _fileGroupOrder is the SortOrder Struct (IceSort Library) which points to the order of the file in the user's group
     * @param _totalSharesMapping is the mapping of the entire shares
     * @param _totalShareOrderMapping is the mapping of the entire shares order using SortOrder Struct (IceSort Library)
     * @param _shareCountMapping is the mapping of all share count
     */
    function deleteFile(
        mapping (uint => File) storage self,
        uint _ein,
        uint _fileIndex,
        IceGlobal.Association storage _globalItemIndividual,
        
        mapping (uint => IceSort.SortOrder) storage _fileOrderMapping,
        mapping (uint => uint) storage _fileCountMapping,
        Group storage _fileGroup,
        IceSort.SortOrder storage _fileGroupOrder,
        
        mapping (uint => mapping(uint => IceGlobal.GlobalRecord)) storage _totalSharesMapping,
        mapping (uint => mapping(uint => IceSort.SortOrder)) storage _totalShareOrderMapping, 
        mapping (uint => uint) storage _shareCountMapping
    )
    public {
        // Check Restrictions
        _fileIndex.condValidItem(_fileCountMapping[_ein]); // Check if the file exists first
        _globalItemIndividual.condUnstampedItem(); // Check if the file is unstamped, can't delete a stamped file
        _fileGroupOrder.condValidSortOrder(self[_fileIndex].associatedGroupFileIndex); //Check if sort order is valid
        condItemMarkedForTransfer(self[_fileIndex]);// Check if the File is not marked for transfer
        
        // Delete File Shares and Global Mapping
        _deleteFileMappings(
            _ein, 
            _globalItemIndividual, 
            _totalSharesMapping, 
            _totalShareOrderMapping, 
            _shareCountMapping
        );
        
        // Delete the latest file now
        delete (self[_fileIndex]);
        
        // Delete File Object
        _deleteFileObject(
            self, 
            _ein, 
            _fileIndex, 
            _fileOrderMapping, 
            _fileCountMapping, 
            _fileGroup
        );
    }
    
    /**
     * @dev Private Function to delete file mappings from a user's FMS system
     * @param _ein is the EIN of the user
     * @param _globalItemIndividual is the Association Struct (IceGlobal Library) that contains additional info about file
     * @param _totalSharesMapping is the mapping of the entire shares
     * @param _totalShareOrderMapping is the mapping of the entire shares order using SortOrder Struct (IceSort Library)
     * @param _shareCountMapping is the mapping of all share count
     */
    function _deleteFileMappings(
        uint _ein,
        IceGlobal.Association storage _globalItemIndividual,
        mapping (uint => mapping(uint => IceGlobal.GlobalRecord)) storage _totalSharesMapping,
        mapping (uint => mapping(uint => IceSort.SortOrder)) storage _totalShareOrderMapping, 
        mapping (uint => uint) storage _shareCountMapping
    ) 
    internal {
        // Remove item from sharing of other users
        _totalSharesMapping.removeAllShares(
            _ein,
            _globalItemIndividual, 
            _totalShareOrderMapping, 
            _shareCountMapping
        );
        
        // Remove from global Record
        _globalItemIndividual.deleteGlobalRecord();
    }
    
    /**
     * @dev Private Function to delete file mappings from a user's FMS system
     * @param _files is the mapping of all pointer to the File Struct (IceFMS Library) passed for a user's FMS
     * @param _ein is the EIN of the user
     * @param _fileIndex is the file index in the user's FMS files mapping
     * @param _fileOrderMapping is the mapping of the files of the primary user's FMS
     * @param _fileCountMapping is the mapping of the file count of all the users
     * @param _fileGroup is the Group Struct (IceFMS Library) under which the file in question is stored
     */
    function _deleteFileObject(
        mapping (uint => File) storage _files,
        uint _ein,
        uint _fileIndex,
        mapping (uint => IceSort.SortOrder) storage _fileOrderMapping,
        mapping (uint => uint) storage _fileCountMapping,
        Group storage _fileGroup
    )
    internal {
        // Remove file from Group which holds the File
        removeFileFromGroup(
            _fileGroup, 
            _files[_fileIndex].associatedGroupFileIndex
        );

        // Swap File
        _files[_fileIndex] = _files[_fileCountMapping[_ein]];
        _fileCountMapping[_ein] = _fileOrderMapping.stichSortOrder(_fileIndex, _fileCountMapping[_ein], 0);
    }

    // 2. FILE TO GROUP FUNCTIONS 
    /**
     * @dev Private Function to add file to a group
     * @param self is the pointer to the relevant Group Struct (IceFMS Library) to which the file has to bee added
     * @param _groupIndex is the index of the group belonging to that user, 0 is reserved for root
     * @param _fileIndex is the index of the file belonging to that user
     * @return associatedGroupIndex is the group index of within the mapping of groups for the specific user
     * @return associatedGroupFileIndex is the index where the file is placed within that group in the specific user's FMS
     */
    function addFileToGroup(
        Group storage self, 
        uint _groupIndex, 
        uint _fileIndex
    )
    public
    returns (
        uint associatedGroupIndex, 
        uint associatedGroupFileIndex
    ) {
        // Add File to a group is just adding the index of that file
        uint currentIndex = self.groupFilesCount;
        self.groupFilesCount = self.groupFilesOrder.addToSortOrder(self.groupFilesOrder[0].prev, currentIndex, _fileIndex);

        // Map group index and group order index in file
        associatedGroupIndex = _groupIndex;
        associatedGroupFileIndex = self.groupFilesCount;
    }

    /**
     * @dev Function to remove file from a group
     * @param self is the pointer to the relevant Group Struct (IceFMS Library) which has the file in the primary user's FMS
     * @param _groupFileOrderIndex is the index of the file order within that group
     */
    function removeFileFromGroup(
        Group storage self, 
        uint _groupFileOrderIndex
    )
    public {
        uint maxIndex = self.groupFilesCount;
        uint pointerID = self.groupFilesOrder[maxIndex].pointerID;

        self.groupFilesCount = self.groupFilesOrder.stichSortOrder(_groupFileOrderIndex, maxIndex, pointerID);
    }

    /**
     * @dev Private Function to remap file from one group to another
     * @param self is the pointer to the File Struct (IceFMS Library) passed
     * @param _existingFileIndex is the file index in the user's FMS files mapping
     * @param _oldGroup is the pointer to the old group where the file was present in the user's FMS
     * @param _newGroup is the pointer to the new group where the file will be moved in the user's FMS
     * @param _newGroupIndex is the index of the new group where file has to be moved
     * @return groupFileIndex is the index of the file stored in that relevant group of the primary user 
     */
    function remapFileToGroup(
        File storage self,
        uint _existingFileIndex,
        Group storage _oldGroup,
        Group storage _newGroup, 
        uint _newGroupIndex
    )
    public
    returns (uint groupFileIndex) {
        // Remove File from existing group
        removeFileFromGroup(_oldGroup, self.associatedGroupFileIndex);

        // Add File to new group
        (self.associatedGroupIndex, self.associatedGroupFileIndex) = addFileToGroup(_newGroup, _newGroupIndex, _existingFileIndex);
        
        // The file added has the asssociated group file index now
        groupFileIndex = self.associatedGroupFileIndex;
    }
    
    /**
     * @dev Function to check that a file has been marked for transfer
     */
    function condItemMarkedForTransfer(
        File storage self
    )
    public view {
        // Check if the group file exists or not
        require (
            (self.fileMeta.markedForTransfer == false),
            "File already marked for Transfer"
        );
    }
    
    /**
     * @dev Function to check that a file has been marked for transferee EIN
     * @param _transfereeEIN is the intended EIN for file transfer
     */
    function condMarkedForTransferee(
        File storage self, 
        uint _transfereeEIN
    )
    public view {
        // Check if the group file exists or not
        require (
            (self.transferEIN == _transfereeEIN),
            "File not marked for Transfers"
        );
    }

    /**
     * @dev Function to check that ID = 0 is not modified as it's reserved item
     * @param _index The index to check
     */
    function condNonReservedItem(uint _index)
    public pure {
        require (
            (_index > 0),
            "Reserved Item"
        );
    }
    
    // 3. GROUP FUNCTIONS
    /**
     * @dev Function to return group info
     * @param self is the pointer to the Group Struct (IceFMS Library) passed
     * @param _groupIndex the index of the group
     * @param _groupCount is the count of the number of groups for that specific user
     * @return index is the index of the group
     * @return name is the name associated with the group
     */
    function getGroup(
        Group storage self,
        uint _groupIndex,
        uint _groupCount
    )
    external view 
    returns (
        uint index, 
        string memory name
    ) {
        // Check constraints
        _groupIndex.condValidItem(_groupCount);
    
        // Logic flow
        index = _groupIndex;
    
        if (_groupIndex == 0) {
            name = "Root";
        }
        else {
            name = self.name;
        }
    }
    
    /**
     * @dev Function to create a new Group for the user
     * @param self is the mapping of all pointer to the Group Struct (IceFMS Library) passed for a user's FMS
     * @param _ein is the EIN of the primary user
     * @param _groupName is the name which should be given to the group
     * @param _groupOrderMapping is the mapping of the Groups Struct (IceFMS Library) of the primary user's FMS
     * @param _groupCountMapping is the mapping of the file count of all the users
     * @param _globalItems is the mapping of all items stored by all users in the Ice FMS
     * @param _globalIndex1 is the initial first index of global items
     * @param _globalIndex2 is the initial second index of global items
     * @return newGlobalIndex1 is the new first index of global items
     * @return newGlobalIndex2 is the new second index of global items
     * @return nextGroupIndex is the new count of the group index after creating a group
     */
    function createGroup(
        mapping (uint => Group) storage self,
        uint _ein,
        string calldata _groupName,
        
        mapping (uint => IceSort.SortOrder) storage _groupOrderMapping, 
        mapping (uint => uint) storage _groupCountMapping,
        
        mapping (uint => mapping(uint => IceGlobal.Association)) storage _globalItems,
        uint _globalIndex1,
        uint _globalIndex2
    )
    external 
    returns (
        uint newGlobalIndex1,
        uint newGlobalIndex2,
        uint nextGroupIndex
    ) {
        // Logic
        (newGlobalIndex1, newGlobalIndex2, nextGroupIndex) = _createGroupInner(
           self, 
           _ein, 
           _groupName, 
           _groupOrderMapping, 
           _groupCountMapping, 
           _globalItems, 
           _globalIndex1, 
           _globalIndex2
        );
    }
    
    /**
     * @dev Private Function to facilitate in creating new Group for the user
     * @param groups is the mapping of all pointer to the Group Struct (IceFMS Library) passed for a user's FMS
     * @param _ein is the EIN of the primary user
     * @param _groupName is the name which should be given to the group
     * @param _groupOrderMapping is the mapping of the Groups Struct (IceFMS Library) of the primary user's FMS
     * @param _groupCountMapping is the mapping of the file count of all the users
     * @param _globalItems is the mapping of all items stored by all users in the Ice FMS
     * @param _globalIndex1 is the initial first index of global items
     * @param _globalIndex2 is the initial second index of global items
     * @return newGlobalIndex1 is the new first index of global items
     * @return newGlobalIndex2 is the new second index of global items
     * @return nextGroupIndex is the new count of the group index after creating a group
     */
    function _createGroupInner(
        mapping (uint => Group) storage groups,
        uint _ein,
        string memory _groupName,
        
        mapping (uint => IceSort.SortOrder) storage _groupOrderMapping, 
        mapping (uint => uint) storage _groupCountMapping,
        
        mapping (uint => mapping(uint => IceGlobal.Association)) storage _globalItems,
        uint _globalIndex1,
        uint _globalIndex2
    )
    internal 
    returns (
        uint newGlobalIndex1,
        uint newGlobalIndex2,
        uint nextGroupIndex
    ) {
        
        // Reserve Global Index
        (newGlobalIndex1, newGlobalIndex2) = IceGlobal.reserveGlobalItemSlot(_globalIndex1, _globalIndex2);

        // Check if this is unitialized, if so, initialize it, reserved value of 0 is skipped as that's root
        nextGroupIndex = _groupCountMapping[_ein].add(1);
        
        // Add to Global Items as well
        _globalItems.addItemToGlobalItems(newGlobalIndex1, newGlobalIndex2, _ein, nextGroupIndex, false, false, 0);
        
        // Assign it to User (EIN)
        groups[nextGroupIndex] = IceFMS.Group(
            IceGlobal.GlobalRecord(newGlobalIndex1, newGlobalIndex2), // Add Record to struct
    
            _groupName, //name of Group
            0 // The group file count
        );

        // Add to Stitch Order & Increment index
        _groupCountMapping[_ein] = _groupOrderMapping.addToSortOrder(_groupOrderMapping[0].prev, _groupCountMapping[_ein], 0);

    }
    
    /**
     * @dev Function to rename an existing group for the user / ein
     * @param self is the pointer to the Group Struct (IceFMS Library) passed
     * @param _groupIndex the index of the group
     * @param _groupCount is the count of the number of groups for that specific user
     * @param _groupName describes the new name of the group
     */
    function renameGroup(
        Group storage self,
        uint _groupIndex, 
        uint _groupCount,
        string calldata _groupName
    )
    external {
        // Check Restrictions
        condNonReservedGroup(_groupIndex);
        _groupIndex.condValidItem(_groupCount);

        // Replace the group name
        self.name = _groupName;
    }
    
    /**
     * @dev Function to delete an existing group for the user / ein
     * @param self is the mapping of all pointer to the Group Struct (IceFMS Library) passed for a user's FMS
     * @param _ein is the EIN of the user
     * @param _groupIndex describes the associated index of the group for the user / ein
     * @param _groupOrderMapping is the mapping of the Groups Struct (IceFMS Library) of the primary user's FMS
     * @param _groupCountMapping is the mapping of the file count of all the users
     * @param _totalSharesMapping is the mapping of the entire shares
     * @param _totalShareOrderMapping is the mapping of the entire shares order using SortOrder Struct (IceSort Library)
     * @param _shareCountMapping is the mapping of all share count
     * @param _globalItems is the mapping of all items stored by all users in the Ice FMS
     */
    function deleteGroup(
        mapping (uint => Group) storage self,
        uint _ein,
        
        uint _groupIndex,
        mapping (uint => IceSort.SortOrder) storage _groupOrderMapping, 
        mapping (uint => uint) storage _groupCountMapping,
        
        mapping (uint => mapping(uint => IceGlobal.GlobalRecord)) storage _totalSharesMapping,
        mapping (uint => mapping(uint => IceSort.SortOrder)) storage _totalShareOrderMapping, 
        mapping (uint => uint) storage _shareCountMapping,
        
        mapping (uint => mapping(uint => IceGlobal.Association)) storage _globalItems
    )
    external 
    returns (uint currentGroupIndex) {
        // Check Restrictions
        condGroupEmpty(self[_groupIndex]); // Check that Group contains no Files
        condNonReservedGroup(_groupIndex);
        _groupIndex.condValidItem(_groupCountMapping[_ein]);
        
        // Check if the group exists or not
        currentGroupIndex = _groupCountMapping[_ein];

        // Remove item from sharing of other users
        IceGlobal.Association storage globalItem = self[_groupIndex].rec.getGlobalItemViaRecord(_globalItems);
        _totalSharesMapping.removeAllShares(
            _ein,
            globalItem, 
            _totalShareOrderMapping, 
            _shareCountMapping
        );
        
        // Deactivate from global record
        globalItem.deleteGlobalRecord();

        // Swap Index mapping & remap the latest group ID if this is not the last group
        self[_groupIndex] = self[currentGroupIndex];
        _groupCountMapping[_ein] = _groupOrderMapping.stichSortOrder(_groupIndex, currentGroupIndex, 0);

        // Delete the latest group now
        delete (self[currentGroupIndex]);
    }
    
    /**
     * @dev Function to check that Group Order is valid
     * @param self is the particular group in question
     */
    function condGroupEmpty(Group storage self)
    public view {
        require (
            (self.groupFilesCount == 0),
            "Group has Files"
        );
    }
    
    /**
     * @dev Function to check that index 0 is not modified as this is Reserved in the Group Struct (IceFMS Library) for root folder
     * @param _index The index to check
     */
    function condNonReservedGroup(uint _index)
    internal pure {
        require (
            (_index > 0),
            "Reserved Item"
        );
    }
    
    // 5. TRANSFER FUNCTIONS
    /**
     * @dev Function to check file transfer conditions before initiating a file transfer 
     * @param self is the entire mapping of all the pointers to the File Struct (IceFMS Library)
     * @param _transfererEIN is the EIN which is transferring the file 
     * @param _transfereeEIN is the EIN to which the file will be transferred
     * @param _fileIndex is the index where the file is stored with respect to the user who is transferring the file
     * @param _fileCountMapping is the mapping of the file count of all the users
     * @param _totalGroupsMapping is the entire mapping of the groups of the Ice FMS
     * @param _blacklist is the entire mapping of the Blacklist for all users
     * @param _globalItems is the mapping of all items stored by all users in the Ice FMS
     * @param _identityRegistry is the pointer to the ERC-1484 Identity Registry
     */
    function doInitiateFileTransferChecks(
        mapping (uint => mapping(uint => File)) storage self,
        
        uint _transfererEIN, 
        uint _transfereeEIN, 
        uint _fileIndex, 
        
        mapping (uint => uint) storage _fileCountMapping,
        mapping (uint => mapping(uint => Group)) storage _totalGroupsMapping,
        mapping (uint => mapping(uint => bool)) storage _blacklist,
        
        mapping (uint => mapping(uint => IceGlobal.Association)) storage _globalItems,
        
        IdentityRegistryInterface _identityRegistry
    )
    external view {
        IceGlobal.condEINExists(_transfereeEIN, _identityRegistry); // Check Valid EIN
        IceGlobal.condUniqueEIN(_transfererEIN, _transfereeEIN); // Check EINs and Unique
        _fileIndex.condValidItem(_fileCountMapping[_transfererEIN]); // Check if the item exists
        self[_transfererEIN][_fileIndex].rec.getGlobalItemViaRecord(_globalItems).condUnstampedItem(); // Check if the File is not stamped
        condItemMarkedForTransfer(self[_transfererEIN][_fileIndex]); // Check if the File is not marked for transfer
        // Check if the Group is not stamped
        _totalGroupsMapping[_transfererEIN][self[_transfererEIN][_fileIndex].associatedGroupIndex].rec.getGlobalItemViaRecord(_globalItems).condUnstampedItem();
        _blacklist[_transfereeEIN].condNotInList(_transfererEIN); // Check if The transfee hasn't blacklisted the file owner
    }
    
    /**
     * @dev Function to do file transfer(Part 1) from previous (current) owner to new owner
     * @param self is the entire mapping of all the pointers to the File Struct (IceFMS Library)
     * @param _transfererEIN is the previous(current) owner EIN
     * @param _transfereeEIN is the EIN of the user to whom the file needs to be transferred
     * @param _fileIndex is the index where file is stored
     * @param _totalFilesOrderMapping is the entire mapping of the files order of the Ice FMS
     * @param _fileCountMapping is the mapping of the file count of all the users
     * @return nextTransfereeIndex is the index number where the file is stored in the recipient user's File Struct mapping 
     */
    function doFileTransferPart1 (
        mapping (uint => mapping(uint => File)) storage self,
        
        uint _transfererEIN, 
        uint _transfereeEIN, 
        uint _fileIndex, 
        
        mapping (uint => mapping(uint => IceSort.SortOrder)) storage _totalFilesOrderMapping, 
        mapping (uint => uint) storage _fileCountMapping
    )
    external 
    returns (uint nextTransfereeIndex) {
        // Check Constraints
        IceGlobal.condCheckUnderflow(_fileCountMapping[_transfererEIN]);
        
        // Get Indexes
        uint currentTransfereeIndex = _fileCountMapping[_transfereeEIN];
        nextTransfereeIndex =  currentTransfereeIndex.add(1);

        // Transfer the file to the transferee & later Delete it for transferer
        self[_transfereeEIN][nextTransfereeIndex] = self[_transfererEIN][_fileIndex];

        // Change file properties and transfer history
        uint8 tc = self[_transfereeEIN][nextTransfereeIndex].fileMeta.transferCount.add(1);

        self[_transfereeEIN][nextTransfereeIndex].transferHistory[tc] = _transfereeEIN;
        self[_transfereeEIN][nextTransfereeIndex].fileMeta.markedForTransfer = false;
        self[_transfereeEIN][nextTransfereeIndex].fileMeta.transferCount = tc;

        // add to transferee sort order & Increment index
        _fileCountMapping[_transfereeEIN] = _totalFilesOrderMapping[_transfereeEIN].addToSortOrder(
            _totalFilesOrderMapping[_transfereeEIN][0].prev, 
            currentTransfereeIndex, 
            0
        );
    }
    
    /**
     * @dev Function to do file transfer(Part 2) from previous (current) owner to new owner
     * @param self is the entire mapping of all the pointers to the File Struct (IceFMS Library)
     * @param _transfereeEIN is the EIN of the user to whom the file needs to be transferred
     * @param _fileIndex is the index where file is stored
     * @param _toRecipientGroup is the intended group of the recipient user where the file should go
     * @param _recipientGroupCount is the number of groups present in the recipient's user FMS system
     * @param _nextTransfereeIndex is the index number where the file is stored in the recipient user's File Struct mapping
     * @param _totalGroupsMapping is the entire mapping of all the groups in Ice FMS
     * @param _globalItems is the mapping of all items stored by all users in the Ice FMS
     */
    function doFileTransferPart2 (
        mapping (uint => mapping(uint => File)) storage self,
        
        uint _transfereeEIN, 
        uint _fileIndex, 
        uint _toRecipientGroup,
        uint _recipientGroupCount,
        uint _nextTransfereeIndex,
        
        mapping (uint => mapping(uint => Group)) storage _totalGroupsMapping,
        mapping (uint => mapping(uint => IceGlobal.Association)) storage _globalItems
    )
    external {
        // Check Constraints
        _toRecipientGroup.condValidItem(_recipientGroupCount); // Check if the group exists
        
        // Add File to transferee group
        (self[_transfereeEIN][_nextTransfereeIndex].associatedGroupIndex, self[_transfereeEIN][_nextTransfereeIndex].associatedGroupFileIndex) = addFileToGroup(
            _totalGroupsMapping[_transfereeEIN][_toRecipientGroup], 
            _toRecipientGroup, 
            _nextTransfereeIndex
        );
        
        // Get global association
        IceGlobal.Association storage globalItem = self[_transfereeEIN][_fileIndex].rec.getGlobalItemViaRecord(_globalItems);

        // Update global file association
        globalItem.ownerInfo.EIN = _transfereeEIN;
        globalItem.ownerInfo.index = _nextTransfereeIndex;
    }
    
    /**
     * @dev Function to initiate requested file transfer in a permissioned manner
     * @param self is the pointer to the File Struct (IceFMS Library) passed
     * @param _transfereeEIN is the EIN to which the file will be transferred
     * @param _transfers is the mapping of all transfers for the transferee's FMS
     * @param _transferOrderMapping is the mapping of the order of transfers for the transferee user's FMS
     * @param _transferCountMapping is the mapping of the entire transfer count for every user
     * @param _globalItems is the mapping of all items stored by all users in the Ice FMS
     */
    function doPermissionedFileTransfer(
        File storage self,
        uint _transfereeEIN,
        
        mapping (uint => IceGlobal.GlobalRecord) storage _transfers,
        mapping (uint => IceSort.SortOrder) storage _transferOrderMapping, 
        mapping (uint => uint) storage _transferCountMapping,
        
        mapping (uint => mapping(uint => IceGlobal.Association)) storage _globalItems
    )
    external {
        _initiatePermissionedFileTransfer (
            self,
            _transfereeEIN,
            
            _transfers,
            _transferOrderMapping,
            _transferCountMapping,
            
            _globalItems
        );
    }
    
    /**
     * @dev Private Function to initiate requested file transfer
     * @param self is the pointer to the File Struct (IceFMS Library) passed
     * @param _transfereeEIN is the EIN to which the file will be transferred
     * @param _transfers is the mapping of all transfers for the transferee's FMS
     * @param _transferOrderMapping is the mapping of the order of transfers for the transferee user's FMS
     * @param _transferCountMapping is the mapping of the entire transfer count for every user
     * @param _globalItems is the mapping of all items stored by all users in the Ice FMS
     */
    function _initiatePermissionedFileTransfer(
        File storage self,
        uint _transfereeEIN,
        
        mapping (uint => IceGlobal.GlobalRecord) storage _transfers,
        mapping (uint => IceSort.SortOrder) storage _transferOrderMapping, 
        mapping (uint => uint) storage _transferCountMapping,
        
        mapping (uint => mapping(uint => IceGlobal.Association)) storage _globalItems
    )
    internal {
        // Check constraints
        self.rec.getGlobalItemViaRecord(_globalItems).condUnstampedItem(); // Check Item is file
        IceGlobal.condCheckOverflow(_transferCountMapping[_transfereeEIN]); // Check for Transfer Overflow 
        
        // Map it to transferee mapping of transfers
        uint nextTransferIndex = _transferCountMapping[_transfereeEIN] + 1;

        // Mark the file for transfer
        self.fileMeta.markedForTransfer = true;
        self.transferEIN = _transfereeEIN;
        self.transferIndex = nextTransferIndex;

        // Create New Transfer
        _transfers[nextTransferIndex] = self.rec;

        // Update sort order and index
        _transferCountMapping[_transfereeEIN] = _transferOrderMapping.addToSortOrder(_transferOrderMapping[0].prev, _transferCountMapping[_transfereeEIN], 0);
    }
    
    /**
     * @dev Function to accept file transfer (part 1) from a user
     * @param self is the entire mapping of all the pointers to the File Struct (IceFMS Library)
     * @param _transfererEIN is the previous(current) owner EIN
     * @param _transfereeEIN is the EIN to which the file will be transferred
     * @param _fileIndex is the index where file is stored
     */
    function acceptFileTransferPart1(
        mapping (uint => mapping(uint => File)) storage self,
        
        uint _transfererEIN, 
        uint _transfereeEIN,
        uint _fileIndex
    )
    external {
        // Check Restrictions
        condMarkedForTransferee(self[_transfererEIN][_fileIndex], _transfereeEIN); // Check if the file is marked for transfer to the recipient
        
        // Set file to normal so that transfer
        self[_transfererEIN][_fileIndex].fileMeta.markedForTransfer = false;
    }
    
    /**
     * @dev Function to accept file transfer (part 2) from a user
     * @param self is the entire mapping of all the pointers to the File Struct (IceFMS Library)
     * @param _transfereeEIN is the EIN to which the file will be transferred
     * @param _transferSpecificIndex is the index of the transfer mapping of the recipient which contains transfer info for that file
     * @param _transfersMapping is the mapping of all transfers for the transferee's FMS
     * @param _transferOrderMapping is the mapping of the order of transfers for the transferee user's FMS
     * @param _transferCountMapping is the mapping of the entire transfer count for every user
     * @param _globalItems is the mapping of all items stored by all users in the Ice FMS
     */
    function acceptFileTransferPart2(
        mapping (uint => mapping(uint => File)) storage self,
        
        uint _transfereeEIN,
        
        uint _transferSpecificIndex, 
        
        mapping (uint => IceGlobal.GlobalRecord) storage _transfersMapping,
        mapping (uint => IceSort.SortOrder) storage _transferOrderMapping, 
        mapping (uint => uint) storage _transferCountMapping,
        
        mapping (uint => mapping(uint => IceGlobal.Association)) storage _globalItems
    )
    external {
        // Finally remove the file from Tranferee Mapping
        removeFileFromTransfereeMapping(
            self,
            
            _transfereeEIN,
            _transferSpecificIndex,
            
            _transfersMapping,
            _transferOrderMapping,
            _transferCountMapping,
            
            _globalItems
        );
    }
    
    /**
     * @dev Function to cancel file transfer inititated by the current owner and / or recipient
     * @param self is the entire mapping of all the pointers to the File Struct (IceFMS Library)
     * @param _transfererEIN is the previous(current) owner EIN
     * @param _transfereeEIN is the EIN to which the file will be transferred
     * @param _fileIndex is the index where file is stored
     * @param _transfersMapping is the mapping of all transfers for the transferee's FMS
     * @param _transferOrderMapping is the mapping of the order of transfers for the transferee user's FMS
     * @param _transferCountMapping is the mapping of the entire transfer count for every user
     * @param _globalItems is the mapping of all items stored by all users in the Ice FMS
     */
    function cancelFileTransfer(
        mapping (uint => mapping(uint => File)) storage self,
        
        uint _transfererEIN,
        uint _transfereeEIN,
        uint _fileIndex,
        
        mapping (uint => IceGlobal.GlobalRecord) storage _transfersMapping,
        mapping (uint => IceSort.SortOrder) storage _transferOrderMapping, 
        mapping (uint => uint) storage _transferCountMapping,
        
        mapping (uint => mapping(uint => IceGlobal.Association)) storage _globalItems
    )
    external {
        // Check constraints
        condMarkedForTransferee(self[_transfererEIN][_fileIndex], _transfereeEIN);
        
        // Logic
        _cancelFileTransfer(
            self,
        
            _transfererEIN,
            _transfereeEIN,
            _fileIndex,
            
            _transfersMapping,
            _transferOrderMapping, 
            _transferCountMapping,
            
            _globalItems
        );
    }
    
    /**
     * @dev Private Function to cancel file transfer inititated by the current owner or the recipient
     * @param self is the entire mapping of all the pointers to the File Struct (IceFMS Library)
     * @param _transfererEIN is the previous(current) owner EIN
     * @param _transfereeEIN is the EIN to which the file will be transferred
     * @param _fileIndex is the index where file is stored
     * @param _transfersMapping is the mapping of all transfers for the transferee's FMS
     * @param _transferOrderMapping is the mapping of the order of transfers for the transferee user's FMS
     * @param _transferCountMapping is the mapping of the entire transfer count for every user
     * @param _globalItems is the mapping of all items stored by all users in the Ice FMS
     */
    function _cancelFileTransfer (
        mapping (uint => mapping(uint => File)) storage self,
        
        uint _transfererEIN,
        uint _transfereeEIN,
        uint _fileIndex,
        
        mapping (uint => IceGlobal.GlobalRecord) storage _transfersMapping,
        mapping (uint => IceSort.SortOrder) storage _transferOrderMapping, 
        mapping (uint => uint) storage _transferCountMapping,
        
        mapping (uint => mapping(uint => IceGlobal.Association)) storage _globalItems
    )
    private {
        // Cancel file transfer
        self[_transfererEIN][_fileIndex].fileMeta.markedForTransfer = false;

        // Remove file from  transferee
        uint transferSpecificIndex = self[_transfererEIN][_fileIndex].transferIndex;
        removeFileFromTransfereeMapping(
            self,
            _transfereeEIN,
            transferSpecificIndex,
            
            _transfersMapping,
            _transferOrderMapping,
            _transferCountMapping,
            
            _globalItems
        );
    }
    
    /**
     * @dev Private Function to remove file from Transfers mapping of Transferee after file is transferred to them
     * @param self is the entire mapping of all the pointers to the File Struct (IceFMS Library)
     * @param _transfereeEIN is the new owner EIN
     * @param _transferSpecificIndex is the index of the association mapping of transfers
     * @param _transfersMapping is the mapping of all transfers for the transferee's FMS
     * @param _transferOrderMapping is the mapping of the order of transfers for the transferee user's FMS
     * @param _transferCountMapping is the mapping of the entire transfer count for every user
     * @param _globalItems is the mapping of all items stored by all users in the Ice FMS
     */
    function removeFileFromTransfereeMapping(
        mapping (uint => mapping(uint => File)) storage self,
        
        uint _transfereeEIN, 
        uint _transferSpecificIndex,
        
        mapping (uint => IceGlobal.GlobalRecord) storage _transfersMapping,
        mapping (uint => IceSort.SortOrder) storage _transferOrderMapping, 
        mapping (uint => uint) storage _transferCountMapping,
        
        mapping (uint => mapping(uint => IceGlobal.Association)) storage _globalItems
    )
    internal {
        // Check Restrictions
        _transfersMapping[_transferSpecificIndex].getGlobalItemViaRecord(_globalItems).condItemIsFile();
        
        // Retrive the swapped item record and change the transferIndex to remap correctly
        IceGlobal.Association memory item = _transfersMapping[_transferSpecificIndex].getGlobalItemViaRecord(_globalItems);

        // Get Cureent Transfer Index
        uint currentTransferIndex = _transferCountMapping[_transfereeEIN];

        require (
            (currentTransferIndex > 0),
            "Index Not Found"
        );

        // Remove the file from transferer, ie swap mapping and stich sort order
        _transfersMapping[_transferSpecificIndex] = _transfersMapping[currentTransferIndex];
        _transferCountMapping[_transfereeEIN] = _transferOrderMapping.stichSortOrder(_transferSpecificIndex, currentTransferIndex, 0);
 
        //Only File is supported
        self[item.ownerInfo.EIN][item.ownerInfo.index].transferIndex = _transferSpecificIndex;
    }
    
    // 6. STRING / BYTE CONVERSION
    /**
     * @dev Helper Function to convert string to bytes32 format
     * @param _source is the string which needs to be converted
     * @return result is the bytes32 representation of that string
     */
    function stringToBytes32(string memory _source) 
    public pure 
    returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(_source);
        string memory tempSource = _source;
        
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }
    
        assembly {
            result := mload(add(tempSource, 32))
        }
    }
    
    /**
     * @dev Helper Function to convert bytes32 to string format
     * @param _x is the bytes32 format which needs to be converted
     * @return result is the string representation of that bytes32 string
     */
    function bytes32ToString(bytes32 _x) 
    public pure 
    returns (string memory result) {
        bytes memory bytesString = new bytes(32);
        uint charCount = 0;
        for (uint j = 0; j < 32; j++) {
            byte char = byte(bytes32(uint(_x) * 2 ** (8 * j)));
            if (char != 0) {
                bytesString[charCount] = char;
                charCount++;
            }
        }
        bytes memory bytesStringTrimmed = new bytes(charCount);
        for (uint j = 0; j < charCount; j++) {
            bytesStringTrimmed[j] = bytesString[j];
        }
        
        result = string(bytesStringTrimmed);
    }
}

/**
 * @title Ice Protocol
 * @author Harsh Rajat
 * @notice Create Protocol Less File Storage, Grouping, Hassle free Encryption / Decryption and Stamping using Snowflake
 * @dev This Contract forms File Storage / Stamping / Encryption part of Hydro Protocols
 */
contract Ice {
    using SafeMath for uint;
    
    using IceGlobal for IceGlobal.GlobalRecord;
    using IceGlobal for IceGlobal.ItemOwner;
    using IceGlobal for IceGlobal.Association;
    using IceGlobal for IceGlobal.UserMeta;
    using IceGlobal for mapping (uint => bool);
    using IceGlobal for mapping (uint8 => IceGlobal.ItemOwner);
    using IceGlobal for mapping (uint => mapping (uint => IceGlobal.Association));
    using IceGlobal for uint;
    
    using IceSort for mapping (uint => IceSort.SortOrder);
    using IceSort for IceSort.SortOrder;
    
    using IceFMS for IceFMS.File;
    using IceFMS for mapping (uint => IceFMS.File);
    using IceFMS for mapping (uint => mapping (uint => IceFMS.File));
    using IceFMS for IceFMS.Group;
    using IceFMS for mapping (uint => IceFMS.Group);
    
    using IceFMSAdv for mapping (uint => IceGlobal.GlobalRecord);
    using IceFMSAdv for mapping (uint => mapping(uint => IceGlobal.GlobalRecord));
    
    /* ***************
    * DEFINE STRUCTURES
    *************** */
    // Done in Libraries
     
    /* ***************
    * DEFINE VARIABLES
    *************** */
    /* for each item stored, ensure they can be retrieved publicly.
     * globalIndex1 and globalIndex2 starts at 0 and will always increment
     * given these indexes, any items can be retrieved.
     */
    mapping (uint => mapping(uint => IceGlobal.Association)) globalItems;
    uint public globalIndex1; // store the first index of association to retrieve files
    uint public globalIndex2; // store the second index of association to retrieve files

    /* for each user (EIN), look up the Transitioon State they have
     * stored on a given index.
     */
    mapping (uint => IceGlobal.UserMeta) public usermeta;

    /* for each user (EIN), look up the file they have
     * stored on a given index.
     */
    mapping (uint => mapping(uint => IceFMS.File)) files;
    mapping (uint => mapping(uint => IceSort.SortOrder)) public fileOrder; // Store round robin order of files
    mapping (uint => uint) public fileCount; // store the maximum file count reached to provide looping functionality

    /* for each user (EIN), look up the group they have
     * stored on a given index. Default group 0 indicates
     * root folder
     */
    mapping (uint => mapping(uint => IceFMS.Group)) groups;
    mapping (uint => mapping(uint => IceSort.SortOrder)) public groupOrder; // Store round robin order of group
    mapping (uint => uint) public groupCount; // store the maximum group count reached to provide looping functionality

    /* for each user (EIN), look up the incoming transfer request
     * stored on a given index.
     */
    mapping (uint => mapping(uint => IceGlobal.GlobalRecord)) public transfers;
    mapping (uint => mapping(uint => IceSort.SortOrder)) public transferOrder; // Store round robin order of transfers
    mapping (uint => uint) public transferCount; // store the maximum transfer request count reached to provide looping functionality

    /* for each user (EIN), look up the incoming sharing files
     * stored on a given index.
     */
    mapping (uint => mapping(uint => IceGlobal.GlobalRecord)) public shares;
    mapping (uint => mapping(uint => IceSort.SortOrder)) public shareOrder; // Store round robin order of sharing
    mapping (uint => uint) public shareCount; // store the maximum shared items count reached to provide looping functionality

    /* for each user (EIN), look up the incoming sharing files
     * stored on a given index.
     */
    mapping (uint => mapping(uint => IceGlobal.GlobalRecord)) public stampings;
    mapping (uint => mapping(uint => IceSort.SortOrder)) public stampingOrder; // Store round robin order of stamping
    mapping (uint => uint) public stampingCount; // store the maximum file index reached to provide looping functionality

    /* for each user (EIN), look up the incoming sharing files
     * stored on a given index.
     */
    mapping (uint => mapping(uint => IceGlobal.GlobalRecord)) public stampingsReq;
    mapping (uint => mapping(uint => IceSort.SortOrder)) public stampingReqOrder; // Store round robin order of stamping requests
    mapping (uint => uint) public stampingReqCount; // store the maximum file index reached to provide looping functionality

    /* for each user (EIN), have a whitelist and blacklist
     * association which can handle certain functions automatically.
     */
    mapping (uint => mapping(uint => bool)) public whitelist;
    mapping (uint => mapping(uint => bool)) public blacklist;

    /* for referencing SnowFlake for Identity Registry (ERC-1484).
     */
    SnowflakeInterface public snowflake;
    IdentityRegistryInterface public identityRegistry;

    /* ***************
    * DEFINE EVENTS
    *************** */
    // When Item is hidden 
    event ItemHidden(uint EIN, uint fileIndex, bool status);
    
    // When Item is Shared
    event ItemShareChange(uint EIN, uint fileIndex);
    
    // When File is created
    event FileCreated(uint EIN, uint fileIndex, string fileName);

    // When File is renamed
    event FileRenamed(uint EIN, uint fileIndex, string fileName);

    // When File is moved
    event FileMoved(uint EIN, uint fileIndex, uint groupIndex, uint groupFileIndex);

    // When File is deleted
    event FileDeleted(uint EIN, uint fileIndex);

    // When Group is created
    event GroupCreated(uint EIN, uint groupIndex, string groupName);

    // When Group is renamed
    event GroupRenamed(uint EIN, uint groupIndex, string groupName);

    // When Group Status is changed
    event GroupDeleted(uint EIN, uint groupIndex, uint groupReplacedIndex);
    
    // When Sharing is completed
    event SharingCompleted(uint EIN, uint index1, uint index2, uint recipientEIN);
    
    // When Sharing is rejected
    event SharingRejected(uint EIN, uint index1, uint index2, uint recipientEIN);
    
    // When Sharing is removed
    event SharingRemoved(uint EIN, uint index1, uint index2, uint recipientEIN);
   
    // When Stamping is initiated
    event StampingInitiated(uint EIN, uint index1, uint index2, uint recipientEIN);
    
    // When Stamping is accepted by the recipient
    event StampingAccepted(uint EIN, uint index1, uint index2, uint recipientEIN);
    
    // When Stamping is rejected by the recipient
    event StampingRejected(uint EIN, uint index1, uint index2, uint recipientEIN);
    
    // When Stamping is revoked by the owner
    event StampingRevoked(uint EIN, uint index1, uint index2, uint recipientEIN);
    
    // When Transfer is initiated
    event FileTransferInitiated(uint EIN, uint index1, uint index2, uint recipientEIN);

    // When Transfer is accepted by the recipient
    event FileTransferAccepted(uint EIN, uint index1, uint index2, uint recipientEIN);

    // When Transfer is rejected by the recipient
    event FileTransferRejected(uint EIN, uint index1, uint index2, uint recipientEIN);

    // When Transfer is revoked by the owner
    event FileTransferRevoked(uint EIN, uint index1, uint index2, uint recipientEIN);

    // When whitelist is updated
    event AddedToWhitelist(uint EIN, uint recipientEIN);
    event RemovedFromWhitelist(uint EIN, uint recipientEIN);

    // When blacklist is updated
    event AddedToBlacklist(uint EIN, uint recipientEIN);
    event RemovedFromBlacklist(uint EIN, uint recipientEIN);

    /* ***************
    * DEFINE CONSTRUCTORS AND RELATED FUNCTIONS
    *************** */
    // CONSTRUCTOR / FUNCTIONS
    constructor (address snowflakeAddress) public {
        snowflake = SnowflakeInterface(snowflakeAddress);
        identityRegistry = IdentityRegistryInterface(snowflake.identityRegistryAddress());
    }

    /* ***************
    * DEFINE CONTRACT FUNCTIONS
    *************** */
    // 1. GLOBAL ITEMS FUNCTIONS
    /**
     * @dev Function to get global items info from the entire File Management System of Ice
     * @param _index1 is the first index of item
     * @param _index2 is the second index of item
     * @return ownerEIN is the EIN of the user who owns the item
     * @return itemRecord is the record of that item in relation to the individual user
     * @return isFile indicates if the item is file or group
     * @return isHidden indicates if the item is hidder or visible
     * @return deleted indicates if the item is already deleted from the individual user perspective
     * @return sharedToCount is the count of sharing the item has
     */
    function getGlobalItems(
        uint _index1, 
        uint _index2
    )
    external view
    returns (
        uint ownerEIN, 
        uint itemRecord, 
        bool isFile, 
        bool isHidden, 
        bool deleted, 
        uint sharedToCount
    ) {
        // Logic
        (ownerEIN, itemRecord, isFile, isHidden, deleted, sharedToCount) = globalItems[_index1][_index2].getGlobalItems();
    }
    
    /**
     * @dev Function to get global items stamping info from the entire File Management System of Ice
     * @param _index1 is the first index of item
     * @param _index2 is the second index of item
     * @return stampingRecipient is the EIN of the recipient for whom stamping is requested / denied / completed
     * @return stampingRecipientIndex is the item index mapped in the mapping of stampingsReq of that recipient
     * @return stampingInitiated either returns 0 (false) or timestamp when the stamping was initiated
     * @return stampingCompleted either returns 0 (false) or timestamp when the stamping was completed
     * @return stampingRejected indicates if the stamping was rejected by the recipient
     */
    function getGlobalItemsStampingInfo(
        uint _index1, 
        uint _index2
    )
    external view
    returns (
        uint stampingRecipient,
        uint stampingRecipientIndex,
        uint32 stampingInitiated,
        uint32 stampingCompleted,
        bool stampingRejected
    ) {
        // Logic
        (
            stampingRecipient, 
            stampingRecipientIndex, 
            stampingInitiated, 
            stampingCompleted, 
            stampingRejected
        ) = globalItems[_index1][_index2].getGlobalItemsStampingInfo();
    }
    
    /**
     * @dev Function to get global items
     * @param _index1 is the first index of item
     * @param _index2 is the second index of item
     * @param _isHidden is the flag to hide that item or not 
     */
    function hideGlobalItem(
        uint _index1, 
        uint _index2, 
        bool _isHidden
    ) 
    external {
        // Get user EIN
        uint ein = identityRegistry.getEIN(msg.sender);
        
        // Check Restrictions
        globalItems[_index1][_index2].condItemOwner(ein);
        
        // Logic
        globalItems[_index1][_index2].isHidden = _isHidden;
        
        // Trigger Event
        emit ItemHidden(ein, globalItems[_index1][_index2].ownerInfo.EIN, _isHidden); 
    }

    /**
     * @dev Function to get info of mapping to user for a specific global item
     * @param _index1 is the first index of global item
     * @param _index2 is the second index of global item
     * @param _ofType indicates the type. 0 - shares, 1 - stampings
     * @param _mappedIndex is the index
     * @return mappedToEIN is the user (EIN)
     * @return atIndex is the specific index in question, only returns on shares types
     * @return timestamp is the time when the file was stamped by the EIN, only returns on stamping types
     */
    function getGlobalItemsMapping(
        uint _index1, 
        uint _index2, 
        uint8 _ofType, 
        uint8 _mappedIndex
    )
    external view
    returns (
        uint mappedToEIN, 
        uint atIndex
    ) {
        // Allocalte based on type.
        if (_ofType == uint8(IceGlobal.AsscProp.sharedTo)) {
            mappedToEIN = globalItems[_index1][_index2].sharedTo[_mappedIndex].EIN;
            atIndex = globalItems[_index1][_index2].sharedTo[_mappedIndex].index;
        }
        else if (_ofType == uint8(IceGlobal.AsscProp.stampedTo)) {
            mappedToEIN = globalItems[_index1][_index2].stampingRecipient.EIN;
            atIndex = globalItems[_index1][_index2].stampingRecipient.index; 
        }
    }
    
    // 2. FILE FUNCTIONS
    /**
     * @dev Function to get the desired amount of files indexes (max 20 at times) of an EIN, the 0 indicates 
     * @param _ein is the EIN of the user
     * @param _seedPointer is the seed of the order from which it should begin
     * @param _limit is the limit of file indexes requested
     * @param _asc is the order by which the files will be presented
     * @return fileIndexes is the array of file indexes for the specified users
     */
    function getFileIndexes(
        uint _ein, 
        uint _seedPointer,
        uint16 _limit, 
        bool _asc
    )
    external view
    returns (uint[20] memory fileIndexes) {
        fileIndexes = fileOrder[_ein].getIndexes(_seedPointer, _limit, _asc);
    }

    /**
     * @dev Function to get file info of an EIN
     * @param _ein is the owner EIN
     * @param _fileIndex is index of the file
     * @return protocol is the protocol used for storing that file (for example: 1 is IPFS, etc, etc). Used to fetch file from JS Library
     * @return protocolMeta contains the additional essential infomation about the protocol if any
     * @return name is the name of the file along with the extension
     * @return hash1 is the 
     * 
     */
    function getFileInfo(
        uint _ein, 
        uint _fileIndex
    )
    external view 
    returns (
        uint8 protocol, 
        bytes memory protocolMeta, 
        string memory fileName, 
        bytes32 fileHash, 
        bytes22 hashExtraInfo,
        uint8 hashFunction,
        uint8 hashSize,
        bool encryptedStatus
    ) {
        // Logic
        (protocol, protocolMeta, fileName, fileHash, hashExtraInfo, hashFunction, hashSize, encryptedStatus) = files[_ein][_fileIndex].getFileInfo();
    }
    
    /**
     * @dev Function to get file info of an EIN
     * @param _ein is the owner EIN
     * @param _fileIndex is index of the file
     */
    function getFileOtherInfo(uint _ein, uint _fileIndex)
    external view
    returns (uint32 timestamp, uint associatedGroupIndex, uint associatedGroupFileIndex) {
        // Logic
        (timestamp, associatedGroupIndex, associatedGroupFileIndex) = files[_ein][_fileIndex].getFileOtherInfo();
    }

    /**
     * @dev Function to get file tranfer info of an EIN
     * @param _ein is the owner EIN
     * @param _fileIndex is index of the file
     */
    function getFileTransferInfo(uint _ein, uint _fileIndex)
    external view
    returns (uint transCount, uint transEIN, uint transIndex, bool forTrans) {
        // Logic
        (transCount, transEIN, transIndex, forTrans) = files[_ein][_fileIndex].getFileTransferInfo();
    }

    /**
     * @dev Function to get file tranfer owner info of an EIN
     * @param _ein is the owner EIN
     * @param _fileIndex is index of the file
     * @param _transferCount is index to poll
     */
    function getFileTransferOwners(uint _ein, uint _fileIndex, uint _transferCount)
    external view
    returns (uint recipientEIN) {
        recipientEIN = files[_ein][_fileIndex].getFileTransferOwners(_transferCount);
    }

    // /**
    //  * @dev Function to add File
    //  * @param _protocol is the protocol used
    //  * @param _protocolMeta is the metadata used by the protocol if any
    //  * @param _name is the name of the file
    //  * @param _hash1 is the first split hash of the stored file
    //  * @param _hash2 is the second split hash of the stored file
    //  * @param _encrypted defines if the file is encrypted or not
    //  * @param _encryptedHash defines the encrypted public key password for the sender address
    //  * @param _groupIndex defines the index of the group of file
    //  */
    function addFile(
        uint8 _op, 
        uint8 _protocol, 
        bytes memory _protocolMeta, 
        bytes32 _name, 
        bytes32 _hash,
        bytes22 _hashExtraInfo,
        uint8 _hashFunction,
        uint8 _hashSize,
        bool _encrypted, 
        bytes32 _encryptedHash, 
        uint _groupIndex
    )
    public {
        // Get user EIN
        uint ein = identityRegistry.getEIN(msg.sender);
        
        // Check constraints
        _groupIndex.condValidItem(groupCount[ein]);

        // To fill with global index if need be
        IceGlobal.GlobalRecord memory rec;
        
        // Create File
        uint nextIndex;
            
        // OP 0 - Normal | 1 - Avatar
        if (_op == 0) {
            // Reserve Global Index
            (globalIndex1, globalIndex2) = IceGlobal.reserveGlobalItemSlot(globalIndex1, globalIndex2);
        
            // Create the record
            rec = IceGlobal.GlobalRecord(globalIndex1, globalIndex2);
        
            // Create File Next Index
            nextIndex = fileCount[ein] + 1;
            
            // Add to globalItems
            globalItems.addItemToGlobalItems(rec.i1, rec.i2, ein, nextIndex, true, false, 0);
        }
        
        // Finally create the file object (EIN)
        files[ein][nextIndex].createFileObject(
            _protocolMeta,
            
            _groupIndex, 
            groups[ein][_groupIndex].groupFilesCount
        );
        
        // Assign global item record 
        files[ein][nextIndex].rec = rec;
        
        // Also create meta object
        files[ein][nextIndex].createFileMetaObject(
            _protocol,
            _name,
            _hash,
            _hashExtraInfo,
            _hashFunction,
            _hashSize,
            _encrypted
        );
        
        // OP 0 - Normal | 1 - Avatar
        if (_op == 0) {
            fileCount[ein] = files[ein][nextIndex].writeFile(
                groups[ein][_groupIndex], 
                _groupIndex, 
                fileOrder[ein], 
                fileCount[ein], 
                nextIndex, 
                ein, 
                _encryptedHash
            );
        }
        else if (_op == 1) {
            usermeta[ein].hasAvatar = true;
        }
        
        // Trigger Event
        emit FileCreated(ein, nextIndex, IceFMS.bytes32ToString(_name));
    }

    // /**
    //  * @dev Function to change File Name
    //  * @param _fileIndex is the index where file is stored
    //  * @param _name is the name of stored file
    //  */
    function changeFileName(
        uint _fileIndex, 
        bytes32 _name
    )
    external {
        // Get user EIN
        uint ein = identityRegistry.getEIN(msg.sender);

        // Logic
        files[ein][_fileIndex].fileMeta.name = _name;

        // Trigger Event
        emit FileRenamed(ein, _fileIndex, IceFMS.bytes32ToString(_name));
    }

    // /**
    //  * @dev Function to move file to another group
    //  * @param _fileIndex is the index where file is stored
    //  * @param _newGroupIndex is the index of the new group where file has to be moved
    //  */
    function moveFileToGroup(
        uint _fileIndex, 
        uint _newGroupIndex
    )
    external {
        // Get user EIN
        uint ein = identityRegistry.getEIN(msg.sender);

        // Logic
        uint groupFileIndex = files[ein][_fileIndex].moveFileToGroup(_fileIndex, groups[ein], groupOrder[ein], _newGroupIndex, globalItems);

        // Trigger Event
        emit FileMoved(ein, _fileIndex, _newGroupIndex, groupFileIndex);
    }

    // /**
    //  * @dev Function to delete file of the owner
    //  * @param _fileIndex is the index where file is stored
    //  */
    function deleteFile(uint _fileIndex)
    external {
        // Get user EIN
        uint ein = identityRegistry.getEIN(msg.sender);

        // Delegate the call
        _deleteFileAnyOwner(ein, _fileIndex);
        
        // Trigger Event
        emit FileDeleted(ein, _fileIndex);
    }

    // /**
    //  * @dev Function to delete file of any EIN
    //  * @param _ein is the owner EIN
    //  * @param _fileIndex is the index where file is stored
    //  */
    function _deleteFileAnyOwner(
        uint _ein, 
        uint _fileIndex
    )
    internal {
        // Logic
        files[_ein].deleteFile(
            _ein,
            _fileIndex,
            files[_ein][_fileIndex].rec.getGlobalItemViaRecord(globalItems),
            
            fileOrder[_ein],
            fileCount,
            groups[_ein][files[_ein][_fileIndex].associatedGroupIndex],
            groupOrder[_ein][files[_ein][_fileIndex].associatedGroupIndex],
            
            shares,
            shareOrder,
            shareCount
        );
    }

    // 3. GROUP FILES FUNCTIONS
    /**
     * @dev Function to get all the files of an EIN associated with a group
     * @param _ein is the owner EIN
     * @param _groupIndex is the index where group is stored
     * @param _seedPointer is the seed of the order from which it should begin
     * @param _limit is the limit of file indexes requested
     * @param _asc is the order by which the files will be presented
     */
    function getGroupFileIndexes(
        uint _ein, 
        uint _groupIndex, 
        uint _seedPointer, 
        uint16 _limit, 
        bool _asc
    )
    external view
    returns (uint[20] memory groupFileIndexes) {
        return groups[_ein][_groupIndex].groupFilesOrder.getIndexes(_seedPointer, _limit, _asc);
    }

    // 4. GROUP FUNCTIONS
    /**
     * @dev Function to return group info for an EIN
     * @param _ein the EIN of the user
     * @param _groupIndex the index of the group
     * @return index is the index of the group
     * @return name is the name associated with the group
     */
    function getGroup(
        uint _ein, 
        uint _groupIndex
    )
    external view
    returns (
        uint index, 
        string memory name
    ) {
        // Logic
        (index, name) = groups[_ein][_groupIndex].getGroup(_groupIndex, groupCount[_ein]);
    }

    /**
     * @dev Function to return group indexes used to retrieve info about group
     * @param _ein the EIN of the user
     * @param _seedPointer is the pointer (index) of the order mapping
     * @param _limit is the number of indexes to return, capped at 20
     * @param _asc is the order of group indexes in Ascending or Descending order
     * @return groupIndexes the indexes of the groups associated with the ein in the preferred order
     */
    function getGroupIndexes(uint _ein, uint _seedPointer, uint16 _limit, bool _asc)
    external view
    returns (uint[20] memory groupIndexes) {
        groupIndexes = groupOrder[_ein].getIndexes(_seedPointer, _limit, _asc);
    }

    /**
     * @dev Function to create a new Group for the user
     * @param _groupName describes the name of the group
     */
    function createGroup(string memory _groupName)
    public {
        // Get user EIN
        uint ein = identityRegistry.getEIN(msg.sender);
        
        // Logic
        uint nextGroupIndex;
        (globalIndex1, globalIndex2, nextGroupIndex) = groups[ein].createGroup(
            ein, 
            _groupName, 
            groupOrder[ein], 
            groupCount, 
            globalItems,
            globalIndex1,
            globalIndex2
        );
        
        // Trigger Event
        emit GroupCreated(ein, nextGroupIndex, _groupName);
    }

    /**
     * @dev Function to rename an existing Group for the user / ein
     * @param _groupIndex describes the associated index of the group for the user / ein
     * @param _groupName describes the new name of the group
     */
    function renameGroup(
        uint _groupIndex, 
        string calldata _groupName
    )
    external  {
        // Get user EIN
        uint ein = identityRegistry.getEIN(msg.sender);

        // Logic
        groups[ein][_groupIndex].renameGroup(_groupIndex, groupCount[ein], _groupName);
        
        // Trigger Event
        emit GroupRenamed(ein, _groupIndex, _groupName);
    }

    /**
     * @dev Function to delete an existing group for the user / ein
     * @param _groupIndex describes the associated index of the group for the user / ein
     */
    function deleteGroup(uint _groupIndex)
    external {
        // Get user EIN
        uint ein = identityRegistry.getEIN(msg.sender);

        // Logic
        uint currentGroupIndex = groups[ein].deleteGroup(
            ein,
            
            _groupIndex,
            groupOrder[ein], 
            groupCount, 
            
            shares,
            shareOrder,
            shareCount,
            
            globalItems
        );
        
        // Trigger Event
        emit GroupDeleted(ein, _groupIndex, currentGroupIndex);
    }

    // 4. SHARING FUNCTIONS
    /**
     * @dev Function to share an item to other users, always called by owner of the Item
     * @param _toEINs are the array of EINs which the item should be shared to
     * @param _itemIndex is the index of the item to be shared to
     * @param _isFile indicates if the item is file or group
     */
    function shareItemToEINs(uint[] calldata _toEINs, uint _itemIndex, bool _isFile)
    external {
        // Get user EIN
        uint ein = identityRegistry.getEIN(msg.sender);
        
        // Check if item is file or group and accordingly check if Item is valid & Logic
        if (_isFile == true) { 
            _itemIndex.condValidItem(fileCount[ein]);
            shares.shareItemToEINs(globalItems, shareOrder, shareCount, blacklist, files[ein][_itemIndex].rec, ein, _toEINs);
        }
        else {
            _itemIndex.condValidItem(groupCount[ein]);
            shares.shareItemToEINs(globalItems, shareOrder, shareCount, blacklist, groups[ein][_itemIndex].rec, ein, _toEINs);
        }
    }

    /**
     * @dev Function to remove a shared item from the multiple user's mapping, always called by owner of the Item
     * @param _fromEINs are the EINs to which the item should be removed from sharing
     * @param _itemIndex is the index of the item on the owner's mapping
     * @param _isFile indicates if the item is file or group 
     */
    function removeShareFromEINs(
        uint[] memory _fromEINs, 
        uint _itemIndex, 
        bool _isFile
    )
    public {
        // Get user EIN
        uint ein = identityRegistry.getEIN(msg.sender);

        // Check if item is file or group and accordingly check if Item is valid & Logic
        IceGlobal.GlobalRecord memory rec;
        if (_isFile == true) { 
            _itemIndex.condValidItem(fileCount[ein]);
            rec = files[ein][_itemIndex].rec;
        }
        else {
            _itemIndex.condValidItem(groupCount[ein]);
            rec = groups[ein][_itemIndex].rec;
        }
        
        shares.removeShareFromEINs(
            ein, 
            _fromEINs,
            globalItems[rec.i1][rec.i2], 
            shareOrder, 
            shareCount
        );
    }
    
    /**
     * @dev Function to remove shared item by the user to whom the item is shared
     * @param _itemIndex is the index of the item in shares
     */
    function removeSharingItemBySharee(uint _itemIndex) 
    external {
        // Logic
        uint shareeEIN = identityRegistry.getEIN(msg.sender);
        IceGlobal.Association storage globalItem = shares[shareeEIN][_itemIndex].getGlobalItemViaRecord(globalItems);
        
        shares[shareeEIN].removeSharingItemBySharee( 
            shareeEIN,
            globalItem, 
            shareOrder[shareeEIN], 
            shareCount
        );
    }
    
    // 5. STAMPING FUNCTIONS
    /**
     * @dev Function to initiate stamping of an item by the owner of that item
     * @param _itemIndex is the index of the item (File or Group)
     * @param _isFile indicates if the item is File or Group
     * @param _recipientEIN is the recipient EIN of the user who has to stamp the item
     */
    function initiateStampingOfItem(
        uint _itemIndex,
        bool _isFile,
        uint _recipientEIN
    )
    external {
        // Logic
        if (_isFile) {
            stampingsReq[_recipientEIN].initiateStampingOfItem(
                stampingReqOrder[_recipientEIN],
                stampingReqCount,
                
                identityRegistry.getEIN(msg.sender),
                _recipientEIN,
                _itemIndex,
                fileCount[identityRegistry.getEIN(msg.sender)],
                
                files[identityRegistry.getEIN(msg.sender)][_itemIndex].rec.getGlobalItemViaRecord(globalItems),
                files[identityRegistry.getEIN(msg.sender)][_itemIndex].rec,
                
                blacklist,
                identityRegistry
            );
            
            // Trigger Event
            emit StampingInitiated(
                identityRegistry.getEIN(msg.sender), 
                files[identityRegistry.getEIN(msg.sender)][_itemIndex].rec.i1, 
                files[identityRegistry.getEIN(msg.sender)][_itemIndex].rec.i2, 
                _recipientEIN
            );
        }
        else {
            stampingsReq[_recipientEIN].initiateStampingOfItem(
                stampingReqOrder[_recipientEIN],
                stampingReqCount,
                
                identityRegistry.getEIN(msg.sender),
                _recipientEIN,
                _itemIndex,
                groupCount[identityRegistry.getEIN(msg.sender)],
                
                groups[identityRegistry.getEIN(msg.sender)][_itemIndex].rec.getGlobalItemViaRecord(globalItems),
                groups[identityRegistry.getEIN(msg.sender)][_itemIndex].rec,
                
                blacklist,
                identityRegistry
            );
        
            // Trigger Event
            emit StampingInitiated(
                identityRegistry.getEIN(msg.sender), 
                groups[identityRegistry.getEIN(msg.sender)][_itemIndex].rec.i1, 
                groups[identityRegistry.getEIN(msg.sender)][_itemIndex].rec.i2, 
                _recipientEIN
            );
        }
    }
    
    /**
     * @dev Function to accept stamping of an item by the intended recipient
     * @param _stampingReqIndex is the index of the item present in the Stamping Requests mapping of the recipient
     */
    function acceptStamping(
        uint _stampingReqIndex
    )
    external {
        // Get user EIN
        uint recipientEIN = identityRegistry.getEIN(msg.sender);
        
        // Logic 
        stampings[recipientEIN].acceptStamping(
            stampingOrder[recipientEIN],
            stampingCount,
            
            stampingsReq[recipientEIN],
            stampingReqOrder[recipientEIN],
            stampingReqCount,
            
            stampingsReq[recipientEIN][_stampingReqIndex].getGlobalItemViaRecord(globalItems),
            
            recipientEIN,
            _stampingReqIndex
        );
        
        // Trigger Event
        emit StampingAccepted(
            identityRegistry.getEIN(msg.sender), 
            stampingsReq[recipientEIN][_stampingReqIndex].i1, 
            stampingsReq[recipientEIN][_stampingReqIndex].i2, 
            recipientEIN
        );
    }
    
    /**
     * @dev Function to revoke stamping of an item only by the owner 
     * @param _ownerItemIndex is the index of the item (File or Group) in relation to the owner of the item 
     * @param _isFile indicates if the item is File or Group
     */
    function revokeStamping(
        uint _ownerItemIndex,
        bool _isFile
    )
    external {
        // Get user EIN
        uint ownerEIN = identityRegistry.getEIN(msg.sender);
        
        // Get recipient info
        IceGlobal.Association storage globalItem = files[ownerEIN][_ownerItemIndex].rec.getGlobalItemViaRecord(globalItems);
        
        if (_isFile == false) {
            globalItem = groups[ownerEIN][_ownerItemIndex].rec.getGlobalItemViaRecord(globalItems);
        }
        
        uint recipientEIN = globalItem.stampingRecipient.EIN;
        uint recipientItemIndex = globalItem.stampingRecipient.index;
        
        // Trigger Event
        emit StampingRevoked(
            ownerEIN, 
            stampingsReq[recipientEIN][recipientItemIndex].i1, 
            stampingsReq[recipientEIN][recipientItemIndex].i2, 
            recipientEIN
        );
        
        // Logic
        stampingsReq[recipientEIN].cancelStamping(
              stampingReqOrder[recipientEIN],
              stampingReqCount,
              recipientEIN,
              recipientItemIndex,
              globalItem
        );
    }
    
    /**
     * @dev Function to reject stamping of an item only by the recipient
     * @param _recipientItemIndex is the index of the item present in the Stamping Requests mapping of the recipient
     */
    function rejectStamping(
        uint _recipientItemIndex
    )
    external {
        // Get user EIN
        uint recipientEIN = identityRegistry.getEIN(msg.sender);
        
        // Logic
        IceGlobal.Association storage globalItem = stampingsReq[recipientEIN][_recipientItemIndex].getGlobalItemViaRecord(globalItems);
        
        // Trigger Event
        emit StampingRejected(
            globalItem.ownerInfo.EIN, 
            stampingsReq[recipientEIN][_recipientItemIndex].i1, 
            stampingsReq[recipientEIN][_recipientItemIndex].i2, 
            recipientEIN
        );
        
        // Reject Stamping
        stampingsReq[recipientEIN].cancelStamping(
              stampingReqOrder[recipientEIN],
              stampingReqCount,
              recipientEIN,
              _recipientItemIndex,
              globalItem
        );
        
        // Map the rejected flag for the owner
        globalItem.stampingRejected = true;
    }
    
    // 6. TRANSFER FILE FUNCTIONS
    /**
     * @dev Function to intiate file transfer to another EIN(user)
     * @param _fileIndex is the index of file for the original user's EIN
     * @param _transfereeEIN is the recipient user's EIN
     */
    function initiateFileTransfer(
        uint _fileIndex, 
        uint _transfereeEIN
    )
    external {
        // Get user EIN
        uint transfererEIN = identityRegistry.getEIN(msg.sender);
        
        // Check Restrictions
        IceFMS.doInitiateFileTransferChecks(
            files,
            
            transfererEIN,
            _transfereeEIN,
            _fileIndex,
            
            fileCount,
            groups,
            blacklist,
            
            globalItems,
            
            identityRegistry
        );
        
        // Check and change flow if white listed
        if (whitelist[_transfereeEIN][transfererEIN] == true) {
            // Directly transfer file, 0 is always root group
            _doDirectFileTransfer(transfererEIN, _transfereeEIN, _fileIndex, 0);
        }
        else {            
            // Trigger Event
            emit FileTransferInitiated(transfererEIN, files[transfererEIN][_fileIndex].rec.i1, files[transfererEIN][_fileIndex].rec.i2, _transfereeEIN);

            // Request based file Transfers
            files[transfererEIN][_fileIndex].doPermissionedFileTransfer(
                _transfereeEIN,
                
                transfers[_transfereeEIN],
                transferOrder[_transfereeEIN],
                transferCount,
                
                globalItems
            );
        }
    }
    
    /**
     * @dev Private Function to do file transfer from previous (current) owner to new owner
     * @param _transfererEIN is the previous(current) owner EIN
     * @param _transfereeEIN is the EIN of the user to whom the file needs to be transferred
     * @param _fileIndex is the index where file is stored in the owner
     * @param _toRecipientGroup is the index of the group where the file is suppose to be for the recipient
     */
    function _doDirectFileTransfer(
        uint _transfererEIN, 
        uint _transfereeEIN, 
        uint _fileIndex, 
        uint _toRecipientGroup
    )
    internal {
        // Trigger Event
        emit FileTransferAccepted(_transfererEIN, files[_transfererEIN][_fileIndex].rec.i1, files[_transfererEIN][_fileIndex].rec.i2, _transfereeEIN);

        // Logic
        uint nextTransfereeIndex = files.doFileTransferPart1 (
            _transfererEIN,
            _transfereeEIN,
            _fileIndex,
            
            fileOrder,
            fileCount
        );
        
        files.doFileTransferPart2 (
            _transfereeEIN, 
            _fileIndex, 
            _toRecipientGroup,
            groupCount[_transfereeEIN],
            nextTransfereeIndex,
            
            groups,
            globalItems
        );

        // Delete File
        _deleteFileAnyOwner(_transfererEIN, _fileIndex);
    }
    
    /**
     * @dev Function to accept file transfer from a user
     * @param _atRecipientTransferIndex is the file mapping stored no the recipient transfers mapping
     * @param _toRecipientGroup is the index of the group where the file is suppose to be for the recipient
     */
    function acceptFileTransfer(
        uint _atRecipientTransferIndex,
        uint _toRecipientGroup
    )
    external {
        // Get user EIN | Transferee initiates this
        uint transfereeEIN = identityRegistry.getEIN(msg.sender);
        
        // Get owner info
        IceGlobal.ItemOwner memory ownerInfo = transfers[transfereeEIN][_atRecipientTransferIndex].getGlobalItemViaRecord(globalItems).ownerInfo;
        
        uint transfererEIN = ownerInfo.EIN;
        uint fileIndex = ownerInfo.index;
        
        // Accept File Transfer Part 1
        files.acceptFileTransferPart1(
            transfererEIN, 
            transfereeEIN,
            fileIndex
        );
        
        // Do file transfer
        _doDirectFileTransfer(transfererEIN, transfereeEIN, fileIndex, _toRecipientGroup);
        
        // Accept File Transfer Part 2
        files.acceptFileTransferPart2(
            transfereeEIN,
            
            _atRecipientTransferIndex,
        
            transfers[transfereeEIN],
            transferOrder[transfereeEIN],
            transferCount,
            
            globalItems
        );
    }

    /**
     * @dev Function to revoke file transfer inititated by the current owner of that file
     * @param _transfereeEIN is the EIN of the user to whom the file needs to be transferred
     * @param _fileIndex is the index where file is stored
     */
    function revokeFileTransfer(
        uint _transfereeEIN,
        uint _fileIndex
    )
    external {
        // Get user EIN | Transferer initiates this
        uint transfererEIN = identityRegistry.getEIN(msg.sender);

        // Logic
        files.cancelFileTransfer(
            transfererEIN,
            _transfereeEIN,
            _fileIndex,
            
            transfers[_transfereeEIN],
            transferOrder[_transfereeEIN],
            transferCount,
            
            globalItems
        );
         
        // Trigger Event
        emit FileTransferRevoked(transfererEIN, files[transfererEIN][_fileIndex].rec.i1, files[transfererEIN][_fileIndex].rec.i2, _transfereeEIN);
    }
    
    /**
     * @dev Function to revoke file transfer inititated by the current owner of that file
     * @param _atRecipientTransferIndex is the file mapping stored no the recipient transfers mapping
     */
    function rejectFileTransfer(
        uint _atRecipientTransferIndex
    )
    external 
    returns (
        uint, uint
    ){
        // Get user EIN | Transferee initiates this
        uint transfereeEIN = identityRegistry.getEIN(msg.sender);
        
        // Get owner info
        IceGlobal.ItemOwner memory ownerInfo = transfers[transfereeEIN][_atRecipientTransferIndex].getGlobalItemViaRecord(globalItems).ownerInfo;
        
        uint transfererEIN = ownerInfo.EIN;
        uint fileIndex = ownerInfo.index;
        
        // Logic
        files.cancelFileTransfer(
            transfererEIN,
            transfereeEIN,
            fileIndex,
            
            transfers[transfereeEIN],
            transferOrder[transfereeEIN],
            transferCount,
            
            globalItems
        );
        
        // Trigger Event
        emit FileTransferRejected(transfererEIN, files[transfererEIN][fileIndex].rec.i1, files[transfererEIN][fileIndex].rec.i2, transfereeEIN);
    }
    
    // 7. WHITELIST / BLACKLIST FUNCTIONS
    /**
     * @dev Add a non-owner user to whitelist
     * @param _nonOwnerEIN is the ein of the recipient
     */
    function addToWhitelist(uint _nonOwnerEIN)
    external {
        // Logic
        uint ein = identityRegistry.getEIN(msg.sender);
        whitelist[ein].addToWhitelist(_nonOwnerEIN, blacklist[ein]);

        // Trigger Event
        emit AddedToWhitelist(ein, _nonOwnerEIN);
    }

    /**
     * @dev Remove a non-owner user from whitelist
     * @param _nonOwnerEIN is the ein of the recipient
     */
    function removeFromWhitelist(uint _nonOwnerEIN)
    external {
        // Logic
        uint ein = identityRegistry.getEIN(msg.sender);
        whitelist[ein].removeFromWhitelist(_nonOwnerEIN, blacklist[ein]);

        // Trigger Event
        emit RemovedFromWhitelist(ein, _nonOwnerEIN);
    }

    /**
     * @dev Remove a non-owner user to blacklist
     * @param _nonOwnerEIN is the ein of the recipient
     */
    function addToBlacklist(uint _nonOwnerEIN)
    external {
        // Logic
        uint ein = identityRegistry.getEIN(msg.sender);
        blacklist[ein].addToBlacklist(_nonOwnerEIN, whitelist[ein]);

        // Trigger Event
        emit AddedToBlacklist(ein, _nonOwnerEIN);
    }

    /**
     * @dev Remove a non-owner user from blacklist
     * @param _nonOwnerEIN is the ein of the recipient
     */
    function removeFromBlacklist(uint _nonOwnerEIN)
    external {
        // Logic
        uint ein = identityRegistry.getEIN(msg.sender);
        blacklist[ein].removeFromBlacklist(_nonOwnerEIN, whitelist[ein]);

        // Trigger Event
        emit RemovedFromBlacklist(ein, _nonOwnerEIN);
    }

    // // *. FOR DEBUGGING CONTRACT
    // /** 
    //  * @dev Private Function to append two strings together
    //  * @param a the first string
    //  * @param b the second string
    //  */
    // function _append(
    //     string memory a, 
    //     string memory b
    // )
    // internal pure
    // returns (string memory) {
    //     return string(abi.encodePacked(a, b));
    // }
    
    // /** 
    //  * @dev Function To Build Groups & File System for users
    //  */
    // function debugBuildFS()
    // public {
    //     createGroup("A.Images");
    //     createGroup("B.Movies");
    //     createGroup("C.Crypto");
    //     createGroup("D.Others");
    //     createGroup("E.AdobeContract");

    //     // Create Files
    //     // addFile(_op, _protocol, _protocolMeta, _name, _hash, _hashExtraInfo, _hashFunction, _hashSize, _encrypted, _encryptedHash, _groupIndex)
    //     addFile(
    //         0, 
    //         1, 
    //         bytes("0x00"), 
    //         IceFMS.stringToBytes32("index.jpg"), 
    //         IceFMS.stringToBytes32("QmTecWfmvvsPdZXuYrLgCTqRj9YgBiAU332s"), 
    //         bytes22("0x00"), 
    //         2, 
    //         3, 
    //         false, 
    //         "", 
    //         0
    //     );
    //     addFile(
    //         0, 
    //         1, 
    //         bytes("0x00"), 
    //         IceFMS.stringToBytes32("family.pdf"), 
    //         IceFMS.stringToBytes32("QmTecWfmvvsPdZXuYrLgCTqRj9YgBiAU332sL4ZCr9iwDnp9q7"), 
    //         bytes22("0x00"), 
    //         2, 
    //         3, 
    //         false, 
    //         "", 
    //         0
    //     );
    //     addFile(
    //         0, 
    //         1, 
    //         bytes("0x00"), 
    //         IceFMS.stringToBytes32("myportrait.jpg"), 
    //         IceFMS.stringToBytes32("L4ZCr9iwDnp9q7QmTecWfmvvsPdZXuYrLgCTqRj9YgBiAU332s"), 
    //         bytes22("0x00"), 
    //         2, 
    //         3, 
    //         false, 
    //         "", 
    //         0
    //     );
    //     addFile(
    //         0, 
    //         1, 
    //         bytes("0x00"), 
    //         IceFMS.stringToBytes32("index.html"), 
    //         IceFMS.stringToBytes32("9iwDnp9q7QmTecWfmvvsPdZXuYrLgCTqRj9YgBiAU332sL4ZCr"), 
    //         bytes22("0x00"), 
    //         2, 
    //         3, 
    //         false, 
    //         "", 
    //         1
    //     );
    //     addFile(
    //         0, 
    //         1, 
    //         bytes("0x00"), 
    //         IceFMS.stringToBytes32("skills.txt"), 
    //         IceFMS.stringToBytes32("qRj9YgBiAU332sQmTecWfmvvsPdZXuYrLgCT"), 
    //         bytes22("0x00"), 
    //         2, 
    //         3, 
    //         false, 
    //         "", 
    //         2
    //     );
    // }

    // // Get Indexes with Names for EIN
    // /** 
    //  * @dev Function to debug indexes and Ice FMS protocol along with names of the items (returns max 20 items)
    //  * @param _ein is the ein of the intended user
    //  * @param _groupIndex is the index associated with the group, only applicable when debugging GroupFiles
    //  * @param _seedPointer indicates from what point the items should be queried
    //  * @param _limit indicates how many items needs to be returned
    //  * @param _asc indicates whether to return the items in ascending order or descending from the _seedPointer provided along with _limit
    //  * @param _for indicates what to debug | 1 is Files, 2 is GroupFiles, 3 is Groups, 4 is shares, 5 is stamping requests, 6 is stampings
    //  */
    // function debugIndexesWithNames(
    //     uint _ein, 
    //     uint _groupIndex, 
    //     uint _seedPointer, 
    //     uint16 _limit, 
    //     bool _asc, 
    //     uint8 _for
    // )
    // external view
    // returns (
    //     uint[20] memory _indexes, 
    //     string memory _names
    // ) {

    //     if (_for == 1) {
    //         _indexes = fileOrder[_ein].getIndexes(_seedPointer, _limit, _asc);
    //     }
    //     else if (_for == 2) {
    //         _indexes = groups[_ein][_groupIndex].groupFilesOrder.getIndexes(_seedPointer, _limit, _asc);
    //     }
    //     else if (_for == 3) {
    //         _indexes = groupOrder[_ein].getIndexes(_seedPointer, _limit, _asc);
    //     }
    //     else if (_for == 4) {
    //         _indexes = shareOrder[_ein].getIndexes(_seedPointer, _limit, _asc);
    //     }
    //     else if (_for == 5) {
    //         _indexes = stampingReqOrder[_ein].getIndexes(_seedPointer, _limit, _asc);
    //     }
    //     else if (_for == 6) {
    //         _indexes = stampingOrder[_ein].getIndexes(_seedPointer, _limit, _asc);
    //     }

    //     uint16 i = 0;
    //     bool completed = false;

    //     while (completed == false) {
    //         string memory name;

    //         // Get Name
    //         if (_for == 1 || _for == 2) {
    //             name = IceFMS.bytes32ToString(files[_ein][_indexes[i]].fileMeta.name);
    //         }
    //         else if (_for == 3) {
    //             name = groups[_ein][_indexes[i]].name;
    //         }
    //         else if (_for == 4) {
    //             IceGlobal.GlobalRecord memory record = shares[_ein][_indexes[i]];
    //             IceGlobal.ItemOwner memory owner = globalItems[record.i1][record.i2].ownerInfo;
                
    //             if (globalItems[record.i1][record.i2].isFile == true) {
    //                 name = IceFMS.bytes32ToString(files[owner.EIN][owner.index].fileMeta.name);
    //             } 
    //             else {
    //                 name = groups[owner.EIN][owner.index].name;
    //             }
    //         }
    //         else if (_for == 5) {
    //             IceGlobal.GlobalRecord memory record = stampingsReq[_ein][_indexes[i]];
    //             IceGlobal.ItemOwner memory owner = globalItems[record.i1][record.i2].ownerInfo;
                
    //             if (globalItems[record.i1][record.i2].isFile == true) {
    //                 name = IceFMS.bytes32ToString(files[owner.EIN][owner.index].fileMeta.name);
    //             } 
    //             else {
    //                 name = groups[owner.EIN][owner.index].name;
    //             }
    //         }
    //         else if (_for == 6) {
    //             IceGlobal.GlobalRecord memory record = stampings[_ein][_indexes[i]];
    //             IceGlobal.ItemOwner memory owner = globalItems[record.i1][record.i2].ownerInfo;
                
    //             if (globalItems[record.i1][record.i2].isFile == true) {
    //                 name = IceFMS.bytes32ToString(files[owner.EIN][owner.index].fileMeta.name);
    //             } 
    //             else {
    //                 name = groups[owner.EIN][owner.index].name;
    //             }
    //         }

    //         // Add To Return Vars
    //         name = _append(name, "|");
    //         _names = _append(_names, name);

    //         i++;

    //         // check status
    //         if (i == _limit || (_indexes[i-1] == _indexes[i])) {
    //             completed = true;
    //         }
    //     }
    // }
}
