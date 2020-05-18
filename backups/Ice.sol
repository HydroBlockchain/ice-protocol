pragma solidity ^0.5.0;

import "./interfaces/SnowflakeInterface.sol";
import "./interfaces/IdentityRegistryInterface.sol";

/**
 * @title Ice Protocol
 * @author Harsh Rajat
 * @notice Create Protocol Less File Storage, Grouping, Hassle free Encryption / Decryption and Stamping using Snowflake
 * @dev This Contract forms File Storage / Stamping / Encryption part of Hydro Protocols
 */
contract Ice {

    /* ***************
    * DEFINE ENUM
    *************** */
    enum NoticeType {info, warning, error}
    enum GlobalItemProp {sharedTo, stampedTo}

    /* ***************
    * DEFINE VARIABLES
    *************** */
    /* for each file stored, ensure they can be retrieved publicly.
     * associationIndex starts at 0 and will always increment
     * given an associationIndex, any file can be retrieved.
     */
    mapping (uint => mapping(uint => Association)) globalItems;
    uint public globalIndex1; // store the first index of association to retrieve files
    uint public globalIndex2; // store the first index of association to retrieve files

    /* for each user (EIN), look up the Transitioon State they have
     * stored on a given index.
     */
    mapping (uint => AtomicityState) public atomicity;

    /* for each user (EIN), look up the file they have
     * stored on a given index.
     */
    mapping (uint => mapping(uint => File)) files;
    mapping (uint => mapping(uint => SortOrder)) public fileOrder; // Store round robin order of files
    mapping (uint => uint) public fileCount; // store the maximum file count reached to provide looping functionality

    /* for each user (EIN), look up the group they have
     * stored on a given index. Default group 0 indicates
     * root folder
     */
    mapping (uint => mapping(uint => Group)) groups;
    mapping (uint => mapping(uint => SortOrder)) public groupOrder; // Store round robin order of group
    mapping (uint => uint) public groupCount; // store the maximum group count reached to provide looping functionality

    /* for each user (EIN), look up the incoming transfer request
     * stored on a given index.
     */
    mapping (uint => mapping(uint => Association)) transfers;
    mapping (uint => mapping(uint => SortOrder)) public transferOrder; // Store round robin order of transfers
    mapping (uint => uint) public transferIndex; // store the maximum transfer request count reached to provide looping functionality

    /* for each user (EIN), look up the incoming sharing files
     * stored on a given index.
     */
    mapping (uint => mapping(uint => GlobalRecord)) public shares;
    mapping (uint => mapping(uint => SortOrder)) public shareOrder; // Store round robin order of sharing
    mapping (uint => uint) public shareCount; // store the maximum shared items count reached to provide looping functionality

    /* for each user (EIN), look up the incoming sharing files
     * stored on a given index.
     */
    mapping (uint => mapping(uint => GlobalRecord)) public stampings;
    mapping (uint => mapping(uint => SortOrder)) public stampingOrder; // Store round robin order of stamping
    mapping (uint => uint) public stampingCount; // store the maximum file index reached to provide looping functionality

    /* for each user (EIN), look up the incoming sharing files
     * stored on a given index.
     */
    mapping (uint => mapping(uint => GlobalRecord)) public stampingsRequest;
    mapping (uint => mapping(uint => SortOrder)) public stampingsRequestOrder; // Store round robin order of stamping requests
    mapping (uint => uint) public stampingsRequestCount; // store the maximum file index reached to provide looping functionality

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
    * DEFINE STRUCTURES
    *************** */
    /* To define ownership info of a given Item.
     */
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

        bool isFile; // whether the Item is File or Group
        bool isHidden; // Whether the item is hidden or not
        bool isStamped; // Whether the item is stamped atleast once
        bool deleted; // whether the association is deleted

        uint8 sharedToCount; // the count of sharing
        uint8 stampedToCount; // the count of stamping

        mapping (uint8 => ItemOwner) sharedTo; // to contain share to
        mapping (uint8 => ItemOwner) stampedTo; // to have stamping reqs
    }

    struct GlobalRecord {
        uint i1; // store associated global index 1 for access
        uint i2; // store associated global index 2 for access
    }

    /* To define File structure of all stored files
     */
    struct File {
        // File Meta Data
        GlobalRecord rec; // store the association in global record
        uint fileOwner; // store file owner EIN

        // File Properties
        uint8 protocol; // store protocol of the file stored | 0 is URL, 1 is IPFS
        bytes protocolMeta; // store metadata of the protocol
        string name; // the name of the file
        string hash; // store the hash of the file for verification | 0x000 for deleted files
        bytes8 ext; // store the extension of the file
        uint32 timestamp; // to store the timestamp of the block when file is created

        // File Properties - Encryption Properties
        bool encrypted; // whether the file is encrypted
        mapping (address => string) encryptedHash; // Maps Individual address to the stored hash

        // File Group Properties
        uint associatedGroupIndex;
        uint associatedGroupFileIndex;

        // File Transfer Properties
        mapping (uint => uint) transferHistory; // To maintain histroy of transfer of all EIN
        uint transferCount; // To maintain the transfer count for mapping
        uint transferEIN; // To record EIN of the user to whom trasnfer is inititated
        uint transferIndex; // To record the transfer specific index of the transferee
        bool markedForTransfer; // Mark the file as transferred
    }

    /* To connect Files in linear grouping,
     * sort of like a folder, 0 or default grooupID is root
     */
    struct Group {
        GlobalRecord rec; // store the association in global record

        string name; // the name of the Group

        mapping (uint => SortOrder) groupFilesOrder; // the order of files in the current group
        uint groupFilesCount; // To keep the count of group files
    }

    /* To define the order required to have double linked list
     */
    struct SortOrder {
        uint next; // the next ID of the order
        uint prev; // the prev ID of the order

        uint pointerID; // what it should point to in the mapping

        bool active; // whether the node is active or not
    }

    /* To define state and flags for Individual things,
     * used in cases where state change should be atomic
     */
    struct AtomicityState {
        bool lockFiles;
        bool lockGroups;
        bool lockTransfers;
        bool lockSharings;
    }

    /* ***************
    * DEFINE EVENTS
    *************** */
    // When File is created
    event FileCreated(
        uint EIN,
        uint fileIndex,
        string fileName
    );

    // When File is renamed
    event FileRenamed(
        uint EIN,
        uint fileIndex,
        string fileName
    );

    // When File is moved
    event FileMoved(
        uint EIN,
        uint fileIndex,
        uint groupIndex,
        uint groupFileIndex
    );

    // When File is deleted
    event FileDeleted(
        uint EIN,
        uint fileIndex
    );

    // When Group is created
    event GroupCreated(
        uint EIN,
        uint groupIndex,
        string groupName
    );

    // When Group is renamed
    event GroupRenamed(
        uint EIN,
        uint groupIndex,
        string groupName
    );

    // When Group Status is changed
    event GroupDeleted(
        uint EIN,
        uint groupIndex,
        uint groupReplacedIndex
    );

    // When Transfer is initiated from owner
    event FileTransferInitiated(
        uint indexed EIN,
        uint indexed transfereeEIN,
        uint indexed fileID
    );

    // When whitelist is updated
    event AddedToWhitelist(
        uint EIN,
        uint recipientEIN
    );

    event RemovedFromWhitelist(
        uint EIN,
        uint recipientEIN
    );

    // When blacklist is updated
    event AddedToBlacklist(
        uint EIN,
        uint recipientEIN
    );

    event RemovedFromBlacklist(
        uint EIN,
        uint recipientEIN
    );

    // Notice Events
    event Notice(
        uint indexed EIN,
        string indexed notice,
        uint indexed statusType
    );

    /* ***************
    * DEFINE CONSTRUCTORS AND RELATED FUNCTIONS
    *************** */
    // CONSTRUCTOR / FUNCTIONS
    address snowflakeAddress = 0xcF1877AC788a303cAcbbfE21b4E8AD08139f54FA; //0xB536a9b68e7c1D2Fd6b9851Af2F955099B3A59a9; // For local use
    constructor (/*address snowflakeAddress*/) public {
        snowflake = SnowflakeInterface(snowflakeAddress);
        identityRegistry = IdentityRegistryInterface(snowflake.identityRegistryAddress());
    }

    /* ***************
    * DEFINE CONTRACT FUNCTIONS
    *************** */
    // 1. GLOBAL ITEMS FUNCTIONS
    /**
     * @dev Function to get global items
     * @param _index1 is the first index of item
     * @param _index2 is the second index of item
     */
    function getGlobalItems(uint _index1, uint _index2)
    external view
    returns (uint ownerEIN, uint itemRecord, bool isFile, bool isHidden, bool deleted, uint sharedToCount, uint stampingReqsCount) {
        ownerEIN = globalItems[_index1][_index2].ownerInfo.EIN;
        itemRecord = globalItems[_index1][_index2].ownerInfo.index;

        isFile = globalItems[_index1][_index2].isFile;
        isHidden = globalItems[_index1][_index2].isHidden;
        deleted = globalItems[_index1][_index2].deleted;

        sharedToCount = globalItems[_index1][_index2].sharedToCount;
        stampingReqsCount = globalItems[_index1][_index2].stampedToCount;
    }

    /**
     * @dev Function to get info of mapping to user for a specific global item
     * @param _index1 is the first index of global item
     * @param _index2 is the second index of global item
     * @param _ofType indicates the type. 0 - shares, 1 - transferReqs
     * @param _mappedIndex is the index
     * @return mappedToEIN is the user (EIN)
     * @return atIndex is the specific index in question
     */
    function getGlobalItemsMapping(uint _index1, uint _index2, uint8 _ofType, uint8 _mappedIndex)
    external view
    returns (uint mappedToEIN, uint atIndex) {
        ItemOwner memory _mappedItem;

        // Allocalte based on type.
        if (_ofType == uint8(GlobalItemProp.sharedTo)) {
            _mappedItem = globalItems[_index1][_index2].sharedTo[_mappedIndex];
        }
        else if (_ofType == uint8(GlobalItemProp.stampedTo)) {
            _mappedItem = globalItems[_index1][_index2].stampedTo[_mappedIndex];
        }

        mappedToEIN = _mappedItem.EIN;
        atIndex = _mappedItem.index;
    }
    
    /**
     * @dev Private Function to get global item via the record struct
     * @param _rec is the GlobalRecord Struct
     */
    function _getGlobalItemViaRecord(GlobalRecord memory _rec)
    internal pure
    returns (uint _i1, uint _i2) {
        _i1 = _rec.i1;
        _i2 = _rec.i2;
    }

    /**
     * @dev Private Function to add item to global items
     * @param _ownerEIN is the EIN of global items
     * @param _itemIndex is the index at which the item exists on the user mapping
     * @param _isFile indicates if the item is file or group
     * @param _isHidden indicates if the item has is hiddden or not
     */
    function _addItemToGlobalItems(uint _ownerEIN, uint _itemIndex, bool _isFile, bool _isHidden, bool _isStamped)
    internal
    returns (uint i1, uint i2){
        // Increment global Item (0, 0 is always reserved | Is User Avatar)
        globalIndex1 = globalIndex1;
        globalIndex2 = globalIndex2 + 1;

        if (globalIndex2 == 0) {
            // This is loopback, Increment newIndex1
            globalIndex1 = globalIndex1 + 1;

            require (
                globalIndex1 > 0,
                "Storage Full"
            );
        }

        // Add item to global item, no stiching it
        globalItems[globalIndex1][globalIndex2] = Association (
            ItemOwner (
                _ownerEIN, // Owner EIN
                _itemIndex // Item stored at what index for that EIN
            ),

            _isFile, // Item is file or group
            _isHidden, // whether stamping is initiated or not
            _isStamped, // whether file is stamped or not
            false, // Item is deleted or still exists

            0, // the count of shared EINs
            0 // the count of stamping requests
        );

        i1 = globalIndex1;
        i2 = globalIndex2;
    }

    /**
     * @dev Private Function to delete a global items
     * @param _rec is the GlobalRecord Struct
     */
    function _deleteGlobalRecord(GlobalRecord memory _rec)
    internal {
        globalItems[_rec.i1][_rec.i2].deleted = true;
    }
    
    function _getEINsForGlobalItemsMapping(mapping (uint8 => ItemOwner) storage _relatedMapping, uint8 _count) 
    internal view 
    returns (uint[32] memory EINs){
        uint8 i = 0;
        while (_count != 0) {
            EINs[i] = _relatedMapping[_count].EIN;
            
            _count--;
        }
    }
    
    /**
     * @dev Private Function to find the relevant mapping index of item mapped in non owner
     * @param _relatedMapping is the passed pointer of relative mapping of global item Association
     * @param _count is the count of relative mapping of global item Association
     * @param _searchForEIN is the non-owner EIN to search
     * @return mappedIndex is the index which is where the relative mapping points to for those items
     */
    function _findGlobalItemsMapping(mapping (uint8 => ItemOwner) storage _relatedMapping, uint8 _count, uint256 _searchForEIN) 
    internal view 
    returns (uint8 mappedIndex) {
        // Logic
        mappedIndex = 0;

        while (_count != 0) {
            if (_relatedMapping[_count].EIN == _searchForEIN) {
                mappedIndex = _count;
                
                _count = 1;
            }
            
            _count--;
        }
    }
    
    /**
     * @dev Private Function to add to global items mapping
     * @param _rec is the Global Record
     * @param _ofType is the type of global item properties 
     * @param _mappedItem is the non-owner mapping of stored item 
     */
    function _addToGlobalItemsMapping(GlobalRecord storage _rec, uint8 _ofType, ItemOwner memory _mappedItem)
    internal
    returns (uint8 _newCount) {
        // Logic
        // Allocalte based on type.
        if (_ofType == uint8(GlobalItemProp.sharedTo)) {
            _newCount = globalItems[_rec.i1][_rec.i2].sharedToCount + 1;
            globalItems[_rec.i1][_rec.i2].sharedTo[_newCount] = _mappedItem;
        }
        else if (_ofType == uint8(GlobalItemProp.stampedTo)) {
            _newCount = globalItems[_rec.i1][_rec.i2].stampedToCount + 1;
            globalItems[_rec.i1][_rec.i2].stampedTo[_newCount] = _mappedItem;
        }

        globalItems[_rec.i1][_rec.i2].stampedToCount = _newCount;
        require (
            (_newCount > globalItems[_rec.i1][_rec.i2].stampedToCount),
            "Global Mapping Full"
        );
    }

    /**
     * @dev Private Function to remove from global items mapping
     * @param _rec is the Global Record
     * @param _mappedIndex is the non-owner mapping of stored item 
     */
    function _removeFromGlobalItemsMapping(GlobalRecord memory _rec, uint8 _mappedIndex)
    internal
    returns (uint8 _newCount) {
        // Logic
        
        // Just swap and deduct
        _newCount = globalItems[_rec.i1][_rec.i2].sharedToCount;
        globalItems[_rec.i1][_rec.i2].sharedTo[_mappedIndex] = globalItems[_rec.i1][_rec.i2].sharedTo[_newCount];

        require (
            (_newCount > 0),
            "Invalid Global Mapping"
        );
        
        _newCount = _newCount - 1;
        globalItems[_rec.i1][_rec.i2].sharedToCount = _newCount;
    }

    // 2. FILE FUNCTIONS
    /**
     * @dev Function to get all the files of an EIN
     * @param _ein is the owner EIN
     * @param _seedPointer is the seed of the order from which it should begin
     * @param _limit is the limit of file indexes requested
     * @param _asc is the order by which the files will be presented
     */
    function getFileIndexes(uint _ein, uint _seedPointer, uint16 _limit, bool _asc)
    external view
    returns (uint[20] memory fileIndexes) {
        fileIndexes = _getIndexes(fileOrder[_ein], _seedPointer, _limit, _asc);
    }

    /**
     * @dev Function to get file info of an EIN
     * @param _ein is the owner EIN
     * @param _fileIndex is index of the file
     */
    function getFile(uint _ein, uint _fileIndex)
    external view
    returns (uint8 protocol, bytes memory protocolMeta, string memory name, string memory hash, bytes8 ext, uint32 timestamp, bool encrypted, uint associatedGroupIndex, uint associatedGroupFileIndex) {
        // Logic
        protocol = files[_ein][_fileIndex].protocol;
        protocolMeta = files[_ein][_fileIndex].protocolMeta;
        name = files[_ein][_fileIndex].name;
        hash = files[_ein][_fileIndex].hash;
        ext = files[_ein][_fileIndex].ext;
        timestamp = files[_ein][_fileIndex].timestamp;

        encrypted = files[_ein][_fileIndex].encrypted;

        associatedGroupIndex = files[_ein][_fileIndex].associatedGroupIndex;
        associatedGroupFileIndex = files[_ein][_fileIndex].associatedGroupFileIndex;
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
        transCount = files[_ein][_fileIndex].transferCount;
        transEIN = files[_ein][_fileIndex].transferEIN;
        transIndex = files[_ein][_fileIndex].transferIndex;
        forTrans = files[_ein][_fileIndex].markedForTransfer;
    }

    /**
     * @dev Function to get file tranfer owner info of an EIN
     * @param _ein is the owner EIN
     * @param _fileIndex is index of the file
     * @param _transferIndex is index to poll
     */
    function getFileTransferOwners(uint _ein, uint _fileIndex, uint _transferIndex)
    external view
    returns (uint recipientEIN) {
        recipientEIN = files[_ein][_fileIndex].transferHistory[_transferIndex];
    }

    /**
     * @dev Function to add File
     * @param _protocol is the protocol used
     * @param _protocolMeta is the metadata used by the protocol if any
     * @param _name is the name of the file
     * @param _hash is the hash of the stored file
     * @param _ext is the extension of the file
     * @param _encrypted defines if the file is encrypted or not
     * @param _encryptedHash defines the encrypted public key password for the sender address
     * @param _groupIndex defines the index of the group of file
     */
    function addFile(uint8 _protocol, bytes memory _protocolMeta, string memory _name, string memory _hash, bytes8 _ext, bool _encrypted, string memory _encryptedHash, uint _groupIndex)
    public {
        // Get user EIN
        uint ein = identityRegistry.getEIN(msg.sender);

        // Check constraints
        _isValidItem(_groupIndex, groupCount[ein]);
        _isFilesOpLocked(ein);
        _isGrpsOpLocked(ein);

        // Set File & Group Atomicity
        atomicity[ein].lockFiles = true;
        atomicity[ein].lockGroups = true;

        // Add to Global Items
        uint index1;
        uint index2;
        (index1, index2) = _addItemToGlobalItems(ein, (fileCount[ein] + 1), true, false, false);

        // Add file to group
        groups[ein][_groupIndex].groupFilesCount = _addFileToGroup(ein, _groupIndex, (fileCount[ein] + 1));

        // Finally create the file it to User (EIN)
        files[ein][(fileCount[ein] + 1)] = File (
            GlobalRecord(
                index1, // Global Index 1
                index2 // Global Index 2
            ),

            ein, // File Owner
            _protocol, // Protocol For Interpretation
            _protocolMeta, // Serialized Hex of Array
            _name, // Name of File
            _hash, // Hash of File
            _ext, // Extension of File
            uint32(now), // Timestamp of File

            _encrypted, // File Encyption

            _groupIndex, // Store the group index
            groups[ein][_groupIndex].groupFilesCount, // Store the group specific file index

            1, // Transfer Count, treat creation as a transfer count
            0, // Transfer EIN
            0, // Transfer Index for Transferee

            false // File is not flagged for Transfer
        );

        // To map encrypted password
        files[ein][(fileCount[ein] + 1)].encryptedHash[msg.sender] = _encryptedHash;

        // To map transfer history
        files[ein][(fileCount[ein] + 1)].transferHistory[0] = ein;

        // Add to Stitch Order & Increment index
        fileCount[ein] = _addToSortOrder(fileOrder[ein], fileCount[ein], 0);

        // Trigger Event
        emit FileCreated(ein, (fileCount[ein] + 1), _name);

        // Reset Files & Group Atomicity
        atomicity[ein].lockFiles = false;
        atomicity[ein].lockGroups = false;
    }

    /**
     * @dev Function to change File Name
     * @param _fileIndex is the index where file is stored
     * @param _name is the name of stored file
     */
    function changeFileName(uint _fileIndex, string calldata _name)
    external {
        // Get user EIN
        uint ein = identityRegistry.getEIN(msg.sender);

        // Logic
        files[ein][_fileIndex].name = _name;

        // Trigger Event
        emit FileRenamed(ein, _fileIndex, _name);
    }

    /**
     * @dev Function to move file to another group
     * @param _fileIndex is the index where file is stored
     * @param _newGroupIndex is the index of the new group where file has to be moved
     */
    function moveFileToGroup(uint _fileIndex, uint _newGroupIndex)
    external {
        // Get user EIN
        uint ein = identityRegistry.getEIN(msg.sender);

        // Check Restrictions
        _isValidGrpOrder(ein, _newGroupIndex); // Check if the new group is valid
        _isUnstampedItem(files[ein][_fileIndex].rec); // Check if the file is unstamped, can't move a stamped file
        _isUnstampedItem(groups[ein][files[ein][_fileIndex].associatedGroupIndex].rec); // Check if the current group is unstamped, can't move a file from stamped group
        _isUnstampedItem(groups[ein][_newGroupIndex].rec); // Check if the new group is unstamped, can't move a file from stamped group
        _isFilesOpLocked(ein); // Check if the files operations are not locked for the user
        _isGrpsOpLocked(ein); // Check if the groups operations are not locked for the user

        // Set Files & Group Atomicity
        atomicity[ein].lockFiles = true;
        atomicity[ein].lockGroups = true;

        uint GFIndex = _remapFileToGroup(ein, files[ein][_fileIndex].associatedGroupIndex, files[ein][_fileIndex].associatedGroupFileIndex, _newGroupIndex);

        // Trigger Event
        emit FileMoved(ein, _fileIndex, _newGroupIndex, GFIndex);

        // Reset Files & Group Atomicity
        atomicity[ein].lockFiles = false;
        atomicity[ein].lockGroups = false;
    }

    /**
     * @dev Function to delete file of the owner
     * @param _fileIndex is the index where file is stored
     */
    function deleteFile(uint _fileIndex)
    external {
        // Get user EIN
        uint ein = identityRegistry.getEIN(msg.sender);

        // Check Restrictions
        _isUnstampedItem(files[ein][_fileIndex].rec); // Check if the file is unstamped, can't delete a stamped file

        // Set Files & Group Atomicity
        atomicity[ein].lockFiles = true;
        atomicity[ein].lockGroups = true;

        _deleteFileAnyOwner(ein, _fileIndex);

        // Reset Files & Group Atomicity
        atomicity[ein].lockFiles = false;
        atomicity[ein].lockGroups = false;
    }

    /**
     * @dev Function to delete file of any EIN
     * @param _ein is the owner EIN
     * @param _fileIndex is the index where file is stored
     */
    function _deleteFileAnyOwner(uint _ein, uint _fileIndex)
    internal {
        // Check Restrictions
        _isValidItem(_fileIndex, fileCount[_ein]);
        _isValidGrpOrder(_ein, files[_ein][_fileIndex].associatedGroupIndex);

        // Get current Index, Stich check previous index so not required to recheck
        uint currentIndex = fileCount[_ein];

        // Remove item from sharing of other users
        _removeAllShares(files[_ein][_fileIndex].rec);
        
        // Deactivate From Global Items
        _deleteGlobalRecord(files[_ein][_fileIndex].rec);

        // Remove from Group which holds the File
        _removeFileFromGroup(_ein, files[_ein][_fileIndex].associatedGroupIndex, files[_ein][_fileIndex].associatedGroupFileIndex);

        // Swap File
        files[_ein][_fileIndex] = files[_ein][currentIndex];
        fileCount[_ein] = _stichSortOrder(fileOrder[_ein], _fileIndex, currentIndex, 0);
        
        // Delete the latest group now
        delete (files[_ein][currentIndex]);
        
        // Trigger Event
        emit FileDeleted(_ein, _fileIndex);
    }

    /**
     * @dev Private Function to add file to a group
     * @param _ein is the EIN of the intended user
     * @param _groupIndex is the index of the group belonging to that user, 0 is reserved for root
     * @param _fileIndex is the index of the file belonging to that user
     */
    function _addFileToGroup(uint _ein, uint _groupIndex, uint _fileIndex)
    internal
    returns (uint) {
        // Add File to a group is just adding the index of that file
        uint currentIndex = groups[_ein][_groupIndex].groupFilesCount;
        groups[_ein][_groupIndex].groupFilesCount = _addToSortOrder(groups[_ein][_groupIndex].groupFilesOrder, currentIndex, _fileIndex);

        // Map group index and group order index in file
        files[_ein][_fileIndex].associatedGroupIndex = _groupIndex;
        files[_ein][_fileIndex].associatedGroupFileIndex = groups[_ein][_groupIndex].groupFilesCount;

        return groups[_ein][_groupIndex].groupFilesCount;
    }

    /**
     * @dev Private Function to remove file from a group
     * @param _ein is the EIN of the intended user
     * @param _groupIndex is the index of the group belonging to that user
     * @param _groupFileOrderIndex is the index of the file order within that group
     */
    function _removeFileFromGroup(uint _ein, uint _groupIndex, uint _groupFileOrderIndex)
    internal {
        uint maxIndex = groups[_ein][_groupIndex].groupFilesCount;
        uint pointerID = groups[_ein][_groupIndex].groupFilesOrder[maxIndex].pointerID;

        groups[_ein][_groupIndex].groupFilesCount = _stichSortOrder(groups[_ein][_groupIndex].groupFilesOrder, _groupFileOrderIndex, maxIndex, pointerID);
    }

    /**
     * @dev Private Function to remap file from one group to another
     * @param _ein is the EIN of the intended user
     * @param _groupIndex is the index of the group belonging to that user, 0 is reserved for root
     * @param _groupFileOrderIndex is the index of the file order within that group
     * @param _newGroupIndex is the index of the new group belonging to that user
     */
    function _remapFileToGroup(uint _ein, uint _groupIndex, uint _groupFileOrderIndex, uint _newGroupIndex)
    internal
    returns (uint) {
        // Get file index for the Association
        uint fileIndex = groups[_ein][_groupIndex].groupFilesOrder[_groupFileOrderIndex].pointerID;

        // Remove File from existing group
        _removeFileFromGroup(_ein, _groupIndex, _groupFileOrderIndex);

        // Add File to new group
        return _addFileToGroup(_ein, _newGroupIndex, fileIndex);
    }

    // 4. GROUP FILES FUNCTIONS
    /**
     * @dev Function to get all the files of an EIN associated with a group
     * @param _ein is the owner EIN
     * @param _groupIndex is the index where group is stored
     * @param _seedPointer is the seed of the order from which it should begin
     * @param _limit is the limit of file indexes requested
     * @param _asc is the order by which the files will be presented
     */
    function getGroupFileIndexes(uint _ein, uint _groupIndex, uint _seedPointer, uint16 _limit, bool _asc)
    external view
    returns (uint[20] memory groupFileIndexes) {
        return _getIndexes(groups[_ein][_groupIndex].groupFilesOrder, _seedPointer, _limit, _asc);
    }

    // 4. GROUP FUNCTIONS
    /**
     * @dev Function to return group info for an EIN
     * @param _ein the EIN of the user
     * @param _groupIndex the index of the group
     * @return index is the index of the group
     * @return name is the name associated with the group
     */
    function getGroup(uint _ein, uint _groupIndex)
    external view
    returns (uint index, string memory name) {
        // Check constraints
        _isValidItem(_groupIndex, groupCount[_ein]);

        // Logic flow
        index = _groupIndex;

        if (_groupIndex == 0) {
            name = "Root";
        }
        else {
            name = groups[_ein][_groupIndex].name;
        }
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
        groupIndexes = _getIndexes(groupOrder[_ein], _seedPointer, _limit, _asc);
    }

    /**
     * @dev Create a new Group for the user
     * @param _groupName describes the name of the group
     */
    function createGroup(string memory _groupName)
    public {
        // Get user EIN
        uint ein = identityRegistry.getEIN(msg.sender);

        // Check Restrictions
        _isGrpsOpLocked(ein);

        // Set Group Atomicity
        atomicity[ein].lockGroups = true;

        // Check if this is unitialized, if so, initialize it, reserved value of 0 is skipped as that's root
        uint currentGroupIndex = groupCount[ein];
        uint nextGroupIndex = currentGroupIndex + 1;

        // Add to Global Items
        uint index1;
        uint index2;
        (index1, index2) = _addItemToGlobalItems(ein, nextGroupIndex, false, false, false);

        // Assign it to User (EIN)
        groups[ein][nextGroupIndex] = Group(
            GlobalRecord(
                index1, // Global Index 1
                index2 // Global Index 2
            ),

            _groupName, //name of Group
            0 // The group file count
        );

        // Add to Stitch Order & Increment index
        groupCount[ein] = _addToSortOrder(groupOrder[ein], currentGroupIndex, 0);

        // Trigger Event
        emit GroupCreated(ein, nextGroupIndex, _groupName);

        // Reset Group Atomicity
        atomicity[ein].lockGroups = false;
    }

    /**
     * @dev Rename an existing Group for the user / ein
     * @param _groupIndex describes the associated index of the group for the user / ein
     * @param _groupName describes the new name of the group
     */
    function renameGroup(uint _groupIndex, string calldata _groupName)
    external  {
        // Get user EIN
        uint ein = identityRegistry.getEIN(msg.sender);

        // Check Restrictions
        _isNonReservedItem(_groupIndex);
        _isValidItem(_groupIndex, groupCount[ein]);

        // Replace the group name
        groups[ein][_groupIndex].name = _groupName;

        // Trigger Event
        emit GroupRenamed(ein, _groupIndex, _groupName);
    }

    /**
     * @dev Delete an existing group for the user / ein
     * @param _groupIndex describes the associated index of the group for the user / ein
     */
    function deleteGroup(uint _groupIndex)
    external {
        // Get user EIN
        uint ein = identityRegistry.getEIN(msg.sender);

        // Check Restrictions
        _isGroupFileFree(ein, _groupIndex); // Check that Group contains no Files
        _isNonReservedItem(_groupIndex);
        _isValidItem(_groupIndex, groupCount[ein]);
        _isGrpsOpLocked(ein);

        // Set Group Atomicity
        atomicity[ein].lockGroups = true;

        // Check if the group exists or not
        uint currentGroupIndex = groupCount[ein];

        // Remove item from sharing of other users
        _removeAllShares(groups[ein][_groupIndex].rec);
        
        // Deactivate from global record
        _deleteGlobalRecord(groups[ein][_groupIndex].rec);

        // Swap Index mapping & remap the latest group ID if this is not the last group
        groups[ein][_groupIndex] = groups[ein][currentGroupIndex];
        groupCount[ein] = _stichSortOrder(groupOrder[ein], _groupIndex, currentGroupIndex, 0);

        // Delete the latest group now
        delete (groups[ein][currentGroupIndex]);

        // Trigger Event
        emit GroupDeleted(ein, _groupIndex, currentGroupIndex);

        // Reset Group Atomicity
        atomicity[ein].lockGroups = false;
    }

    // 5. SHARING FUNCTIONS
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

        // Check Restriction
        _isSharingsOpLocked(ein); // Check if sharing operations are locked or not for the owner

        // Logic
        // Set Lock
        atomicity[ein].lockSharings = true;

        // Warn: Unbounded Loop
        for (uint i=0; i < _toEINs.length; i++) {
            // call share for each EIN you want to share with
            // Since its multiple share, don't put require blacklist but ignore the share
            // if owner of the file is in blacklist
            if (blacklist[_toEINs[i]][ein] == false) {
                _shareItemToEIN(ein, _toEINs[i], _itemIndex, _isFile);
            }
        }

        // Reset Lock
        atomicity[ein].lockSharings = false;
    }

    /**
     * @dev Function to remove a shared item from the multiple user's mapping, always called by owner of the Item
     * @param _toEINs are the EINs to which the item should be removed from sharing
     * @param _itemIndex is the index of the item on the owner's mapping
     * @param _isFile indicates if the item is file or group 
     */
    function removeShareFromEINs(uint[32] memory _toEINs, uint _itemIndex, bool _isFile)
    public {
        // Get user EIN
        uint ein = identityRegistry.getEIN(msg.sender);

        // Check Restriction
        _isSharingsOpLocked(ein); // Check if sharing operations are locked or not for the owner

        // Logic
        // Set Lock
        atomicity[ein].lockSharings = true;
        
        // Get reference of global item record
        GlobalRecord memory rec;
        if (_isFile == true) {
            // is file
            rec = files[ein][_itemIndex].rec;
        }
        else {
            // is group
            rec = groups[ein][_itemIndex].rec;
        }

        // Adjust for valid loop
        uint count = globalItems[rec.i1][rec.i2].sharedToCount;
        for (uint i=0; i < count; i++) {
            // call share for each EIN you want to remove the share with
            _removeShareFromEIN(_toEINs[i], rec, globalItems[rec.i1][rec.i2]);
        }

        // Reset Lock
        atomicity[ein].lockSharings = false;
    }
    
    /**
     * @dev Function to remove shared item by the non owner of that item
     * @param _itemIndex is the index of the item in shares
     */
    function removeSharingItemNonOwner(uint _itemIndex) 
    external {
        // Get user EIN
        uint ein = identityRegistry.getEIN(msg.sender);
        
        // Logic
        GlobalRecord memory rec = shares[ein][_itemIndex];
        _removeShareFromEIN(ein, shares[ein][_itemIndex], globalItems[rec.i1][rec.i2]); // Handles atomicity and other Restrictions
    }
    
    /**
     * @dev Private Function to share an item to Individual user
     * @param _ein is the EIN to of the owner
     * @param _toEIN is the EIN to which the item should be shared to
     * @param _itemIndex is the index of the item to be shared to
     * @param _isFile indicates if the item is file or group
     */
    function _shareItemToEIN(uint _ein, uint _toEIN, uint _itemIndex, bool _isFile)
    internal {
        // Check Restrictions
        _isNonOwner(_toEIN); // Recipient EIN should not be the owner
        
        // Logic
        // Set Lock
        atomicity[_toEIN].lockSharings = true;

        // Create Sharing
        uint curIndex = shareCount[_toEIN];
        uint nextIndex = curIndex + 1;

        // no need to require as share can be multiple
        // and thus should not hamper other sharings
        if (nextIndex > curIndex) {
            if (_isFile == true) {
                // is file
                shares[_toEIN][nextIndex] = files[_ein][_itemIndex].rec;
            }
            else {
                // is group
                shares[_toEIN][nextIndex] = groups[_ein][_itemIndex].rec;
            }

            // Add to share order & global mapping
            shareCount[_toEIN] = _addToSortOrder(shareOrder[_toEIN], curIndex, 0);
            _addToGlobalItemsMapping(shares[_toEIN][nextIndex], uint8(GlobalItemProp.sharedTo), ItemOwner(_toEIN, nextIndex));
        }

        // Reset Lock
        atomicity[_toEIN].lockSharings = false;
    }

    /**
     * @dev Private Function to remove a shared item from the user's mapping
     * @param _toEIN is the EIN to which the item should be removed from sharing
     * @param _rec is the global record of the file
     * @param _globalItem is the pointer to the global item
     */
    function _removeShareFromEIN(uint _toEIN, GlobalRecord memory _rec, Association storage _globalItem)
    internal {
        // Check Restrictions
        _isNonOwner(_toEIN); // Recipient EIN should not be the owner

        // Logic
        // Set Lock
        atomicity[_toEIN].lockSharings = true;

        // Create Sharing
        uint curIndex = shareCount[_toEIN];

        // no need to require as share can be multiple
        // and thus should not hamper other sharings removals
        if (curIndex > 0) {
            uint8 mappedIndex = _findGlobalItemsMapping(_globalItem.sharedTo, _globalItem.sharedToCount, _toEIN);
            
            // Only proceed if mapping if found 
            if (mappedIndex > 0) {
                uint _itemIndex = _globalItem.sharedTo[mappedIndex].index;
                
                // Remove the share from global items mapping
                _removeFromGlobalItemsMapping(_rec, mappedIndex);
                
                // Swap the shares, then Reove from share order & stich
                shares[_toEIN][_itemIndex] = shares[_toEIN][curIndex];
                shareCount[_toEIN] = _stichSortOrder(shareOrder[_toEIN], _itemIndex, curIndex, 0);
            }
        }

        // Reset Lock
        atomicity[_toEIN].lockSharings = false;
    }
    
    /**
     * @dev Function to remove all shares of an Item, always called by owner of the Item
     * @param _rec is the global item record index 
     */
    function _removeAllShares(GlobalRecord memory _rec) 
    internal {
        // Get user EIN
        uint ein = identityRegistry.getEIN(msg.sender);

        // Check Restriction
        _isSharingsOpLocked(ein); // Check if sharing operations are locked or not for the owner

        // Logic
        // get and pass all EINs, remove share takes care of locking
        uint[32] memory eins = _getEINsForGlobalItemsMapping(globalItems[_rec.i1][_rec.i2].sharedTo, globalItems[_rec.i1][_rec.i2].sharedToCount);
        removeShareFromEINs(eins, globalItems[_rec.i1][_rec.i2].ownerInfo.index, globalItems[_rec.i1][_rec.i2].isFile);
        
        // just adjust share count 
        globalItems[_rec.i1][_rec.i2].sharedToCount = 0;
    }
    // 6. STAMPING FUNCTIONS

    // 8. WHITELIST / BLACKLIST FUNCTIONS
    /**
     * @dev Add a non-owner user to whitelist
     * @param _nonOwnerEIN is the ein of the recipient
     */
    function addToWhitelist(uint _nonOwnerEIN)
    external {
        // Get user EIN
        uint ein = identityRegistry.getEIN(msg.sender);

        // Check Restrictions
        _isNotBlacklist(ein, _nonOwnerEIN);

        // Logic
        whitelist[ein][_nonOwnerEIN] = true;

        // Trigger Event
        emit AddedToWhitelist(ein, _nonOwnerEIN);
    }

    /**
     * @dev Remove a non-owner user from whitelist
     * @param _nonOwnerEIN is the ein of the recipient
     */
    function removeFromWhitelist(uint _nonOwnerEIN)
    external {
        // Get user EIN
        uint ein = identityRegistry.getEIN(msg.sender);

        // Check Restrictions
        _isNotBlacklist(ein, _nonOwnerEIN);

        // Logic
        whitelist[ein][_nonOwnerEIN] = false;

        // Trigger Event
        emit RemovedFromWhitelist(ein, _nonOwnerEIN);
    }

    /**
     * @dev Remove a non-owner user to blacklist
     * @param _nonOwnerEIN is the ein of the recipient
     */
    function addToBlacklist(uint _nonOwnerEIN)
    external {
        // Get user EIN
        uint ein = identityRegistry.getEIN(msg.sender);

        // Check Restrictions
        _isNotWhitelist(ein, _nonOwnerEIN);

        // Logic
        blacklist[ein][_nonOwnerEIN] = true;

        // Trigger Event
        emit AddedToBlacklist(ein, _nonOwnerEIN);
    }

    /**
     * @dev Remove a non-owner user from blacklist
     * @param _nonOwnerEIN is the ein of the recipient
     */
    function removeFromBlacklist(uint _nonOwnerEIN)
    external {
        // Get user EIN
        uint ein = identityRegistry.getEIN(msg.sender);

        // Check Restrictions
        _isNotWhitelist(ein, _nonOwnerEIN);

        // Logic
        whitelist[ein][_nonOwnerEIN] = false;

        // Trigger Event
        emit RemovedFromBlacklist(ein, _nonOwnerEIN);
    }

    // *. REFERENTIAL INDEXES FUNCTIONS
    /**
     * @dev Private Function to return maximum 20 Indexes of Files, Groups, Transfers,
     * etc based on their SortOrder. 0 is always reserved but will point to Root in Group & Avatar in Files
     * @param _orderMapping is the relevant sort order of Files, Groups, Transfers, etc
     * @param _seedPointer is the pointer (index) of the order mapping
     * @param _limit is the number of files requested | Maximum of 20 can be retrieved
     * @param _asc is the order, i.e. Ascending or Descending
     */
    function _getIndexes(mapping(uint => SortOrder) storage _orderMapping, uint _seedPointer, uint16 _limit, bool _asc)
    internal view
    returns (uint[20] memory sortedIndexes) {
        uint next;
        uint prev;
        uint pointerID;
        bool active;

        // Get initial Order
        (prev, next, pointerID, active) = _getOrder(_orderMapping, _seedPointer);

        // Get Previous or Next Order | Round Robin Fashion
        if (_asc == true) {
            // Ascending Order
            (prev, next, pointerID, active) = _getOrder(_orderMapping, next);
        }
        else {
            // Descending Order
            (prev, next, pointerID, active) = _getOrder(_orderMapping, prev);
        }

        uint16 i = 0;

        if (_limit >= 20) {
            _limit = 20; // always account for root
        }

        while (_limit != 0) {

            if (active == false || pointerID == 0) {
                _limit = 0;

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
                    (prev, next, pointerID, active) = _getOrder(_orderMapping, next);
                }
                else {
                    // Descending Order
                    (prev, next, pointerID, active) = _getOrder(_orderMapping, prev);
                }

                // Increment counter
                i++;

                // Decrease Limit
                _limit--;
            }
        }
    }

    // *. DOUBLE LINKED LIST (ROUND ROBIN) FOR OPTIMIZATION FUNCTIONS / DELETE / ADD / ETC
    /**
     * @dev Private Function to facilitate returning of double linked list used
     * @param _orderMapping is the relevant sort order of Files, Groups, Transfers, etc
     * @param _seedPointer is the pointer (index) of the order mapping
     */
    function _getOrder(mapping(uint => SortOrder) storage _orderMapping, uint _seedPointer)
    internal view
    returns (uint prev, uint next, uint pointerID, bool active) {
        prev = _orderMapping[_seedPointer].prev;
        next = _orderMapping[_seedPointer].next;
        pointerID = _orderMapping[_seedPointer].pointerID;
        active = _orderMapping[_seedPointer].active;
    }

    /**
     * @dev Private Function to facilitate adding of double linked list used to preserve order and form cicular linked list
     * @param _orderMapping is the relevant sort order of Files, Groups, Transfers, etc
     * @param _currentIndex is the index which will be maximum
     * @param _pointerID is the ID to which it should point to, pass 0 to calculate on existing logic flow
     */
    function _addToSortOrder(mapping(uint => SortOrder) storage _orderMapping, uint _currentIndex, uint _pointerID)
    internal
    returns (uint) {
        // Next Index is always +1
        uint nextIndex = _currentIndex + 1;

        require (
            (nextIndex > _currentIndex || _pointerID != 0),
            "Slots Full"
        );

        // Assign current order to next pointer
        _orderMapping[_currentIndex].next = nextIndex;
        _orderMapping[_currentIndex].active = true;

        // Special case of root of sort order
        if (_currentIndex == 0) {
            _orderMapping[0].next = nextIndex;
        }

        // Assign initial group prev order
        _orderMapping[0].prev = nextIndex;

        // Whether This is assigned or calculated
        uint pointerID;
        if (_pointerID == 0) {
            pointerID = nextIndex;
        }
        else {
            pointerID = _pointerID;
        }

        // Assign next group order pointer and prev pointer
        _orderMapping[nextIndex] = SortOrder(
            0, // next index
            _currentIndex, // prev index
            pointerID, // pointerID
            true // mark as active
        );

        return nextIndex;
    }

    /**
     * @dev Private Function to facilitate stiching of double linked list used to preserve order with delete
     * @param _orderMapping is the relevant sort order of Files, Groups, Transfer, etc
     * @param _remappedIndex is the index which is swapped to from the latest index
     * @param _maxIndex is the index which will always be maximum
     * @param _pointerID is the ID to which it should point to, pass 0 to calculate on existing logic flow
     */
    function _stichSortOrder(mapping(uint => SortOrder) storage _orderMapping, uint _remappedIndex, uint _maxIndex, uint _pointerID)
    internal
    returns (uint){

        // Stich Order
        uint prevGroupIndex = _orderMapping[_remappedIndex].prev;
        uint nextGroupIndex = _orderMapping[_remappedIndex].next;

        _orderMapping[prevGroupIndex].next = nextGroupIndex;
        _orderMapping[nextGroupIndex].prev = prevGroupIndex;

        // Check if this is not the top order number
        if (_remappedIndex != _maxIndex) {
            // Change order mapping and remap
            _orderMapping[_remappedIndex] = _orderMapping[_maxIndex];
            if (_pointerID == 0) {
                _orderMapping[_remappedIndex].pointerID = _remappedIndex;
            }
            else {
                _orderMapping[_remappedIndex].pointerID = _pointerID;
            }
            _orderMapping[_orderMapping[_remappedIndex].next].prev = _remappedIndex;
            _orderMapping[_orderMapping[_remappedIndex].prev].next = _remappedIndex;
        }

        // Turn off the non-stich group
        _orderMapping[_maxIndex].active = false;

        // Decrement count index if it's non-zero
        require (
            (_maxIndex > 0),
            "Item Not Found"
        );

        // return new index
        return _maxIndex - 1;
    }

    // *. GENERAL CONTRACT HELPERS
    /** @dev Private Function to append two strings together
     * @param a the first string
     * @param b the second string
     */
    function _append(string memory a, string memory b)
    internal pure
    returns (string memory) {
        return string(abi.encodePacked(a, b));
    }

    /* ***************
    * DEFINE MODIFIERS AS INTERNAL VIEW FUNTIONS
    *************** */
    /**
     * @dev Private Function to check that only owner can have access
     * @param _ein The EIN of the file Owner
     */
    function _isOwner(uint _ein)
    internal view {
        require (
            (identityRegistry.getEIN(msg.sender) == _ein),
            "Only Owner"
        );
    }

    /**
     * @dev Private Function to check that only non-owner can have access
     * @param _ein The EIN of the file Owner
     */
    function _isNonOwner(uint _ein)
    internal view {
        require (
            (identityRegistry.getEIN(msg.sender) != _ein),
            "Only Non-Owner"
        );
    }

    /**
     * @dev Private Function to check that only owner of EIN can access this
     * @param _ownerEIN The EIN of the file Owner
     * @param _fileIndex The index of the file
     */
    function _isFileOwner(uint _ownerEIN, uint _fileIndex)
    internal view {
        require (
            (identityRegistry.getEIN(msg.sender) == files[_ownerEIN][_fileIndex].fileOwner),
            "Only File Owner"
        );
    }

    /**
     * @dev Private Function to check that only non-owner of EIN can access this
     * @param _ownerEIN The EIN of the file Owner
     * @param _fileIndex The index of the file
     */
    function _isFileNonOwner(uint _ownerEIN, uint _fileIndex)
    internal view {
        require (
            (identityRegistry.getEIN(msg.sender) != files[_ownerEIN][_fileIndex].fileOwner),
            "Only File Non-Owner"
        );
    }

    /**
     * @dev Private Function to check that only valid EINs can have access
     * @param _ein The EIN of the Passer
     */
    function _isValidEIN(uint _ein)
    internal view {
        require (
            (identityRegistry.identityExists(_ein) == true),
            "EIN not Found"
        );
    }

    /**
     * @dev Private Function to check that only unique EINs can have access
     * @param _ein1 The First EIN
     * @param _ein2 The Second EIN
     */
    function _isUnqEIN(uint _ein1, uint _ein2)
    internal pure {
        require (
            (_ein1 != _ein2),
            "Same EINs"
        );
    }

    /**
     * @dev Private Function to check that a file exists for the current EIN
     * @param _fileIndex The index of the file
     */
    function _doesFileExists(uint _fileIndex)
    internal view {
        require (
            (_fileIndex <= fileCount[identityRegistry.getEIN(msg.sender)]),
            "File not Found"
        );
    }

    /**
     * @dev Private Function to check that a file has been marked for transferee EIN
     * @param _fileIndex The index of the file
     */
    function _isMarkedForTransferee(uint _fileOwnerEIN, uint _fileIndex, uint _transfereeEIN)
    internal view {
        // Check if the group file exists or not
        require (
            (files[_fileOwnerEIN][_fileIndex].transferEIN == _transfereeEIN),
            "File not marked for Transfers"
        );
    }

    /**
     * @dev Private Function to check that a file hasn't been marked for stamping
     * @param _rec is struct record containing global association
     */
    function _isUnstampedItem(GlobalRecord memory _rec)
    internal view {
        // Check if the group file exists or not
        require (
            (globalItems[_rec.i1][_rec.i2].isStamped == false),
            "Item Stamped"
        );
    }

    /**
     * @dev Private Function to check that Rooot ID = 0 is not modified as this is root
     * @param _index The index to check
     */
    function _isNonReservedItem(uint _index)
    internal pure {
        require (
            (_index > 0),
            "Reserved Item"
        );
    }

    /**
     * @dev Private Function to check that Group Order is valid
     * @param _ein is the EIN of the target user
     * @param _groupIndex The index of the group order
     */
    function _isGroupFileFree(uint _ein, uint _groupIndex)
    internal view {
        require (
            (groups[_ein][_groupIndex].groupFilesCount == 0),
            "Group has Files"
        );
    }

    /**
     * @dev Private Function to check if an item exists
     * @param _itemIndex the index of the item
     * @param _itemCount is the count of that mapping
     */
    function _isValidItem(uint _itemIndex, uint _itemCount)
    internal pure {
        require (
            (_itemIndex <= _itemCount),
            "Item Not Found"
        );
    }

    /**
     * @dev Private Function to check that Group Order is valid
     * @param _ein is the EIN of the target user
     * @param _groupOrderIndex The index of the group order
     */
    function _isValidGrpOrder(uint _ein, uint _groupOrderIndex)
    internal view {
        require (
            (_groupOrderIndex == 0 || groupOrder[_ein][_groupOrderIndex].active == true),
            "Group Order not Found"
        );
    }

    /**
     * @dev Private Function to check that operation of Files is currently locked or not
     * @param _ein is the EIN of the target user
     */
    function _isFilesOpLocked(uint _ein)
    internal view {
        require (
          (atomicity[_ein].lockFiles == false),
          "Files Locked"
        );
    }

    /**
     * @dev Private Function to check that operation of Groups is currently locked or not
     * @param _ein is the EIN of the target user
     */
    function _isGrpsOpLocked(uint _ein)
    internal view {
        require (
          (atomicity[_ein].lockGroups == false),
          "Groups Locked"
        );
    }

    /**
     * @dev Private Function to check that operation of Sharings is currently locked or not
     * @param _ein is the EIN of the target user
     */
    function _isSharingsOpLocked(uint _ein)
    internal view {
        require (
          (atomicity[_ein].lockSharings == false),
          "Sharing Locked"
        );
    }

    /**
     * @dev Private Function to check that operation of Transfers is currently locked or not
     * @param _ein is the EIN of the target user
     */
    function _isTransfersOpLocked(uint _ein)
    internal view {
        require (
          (atomicity[_ein].lockTransfers == false),
          "Transfers Locked"
        );
    }

    /**
     * @dev Private Function to check if the user is not blacklisted by the current user
     * @param _ein is the EIN of the self
     * @param _otherEIN is the EIN of the target user
     */
    function _isNotBlacklist(uint _ein, uint _otherEIN)
    internal view {
        require (
            (blacklist[_ein][_otherEIN] == false),
            "EIN Blacklisted"
        );
    }

    /**
     * @dev Private Function to check if the user is not whitelisted by the current user
     * @param _ein is the EIN of the self
     * @param _otherEIN is the EIN of the target user
     */
    function _isNotWhitelist(uint _ein, uint _otherEIN)
    internal view {
        require (
            (whitelist[_ein][_otherEIN] == false),
            "EIN Whitelisted"
        );
    }

    // *. FOR DEBUGGING CONTRACT
    // To Build Groups & File System for users
    function debugBuildFS()
    public {
        // Create Groups
        createGroup("A.Images");
        createGroup("B.Movies");
        createGroup("C.Crypto");
        createGroup("D.Others");
        createGroup("E.AdobeContract");

        // Create Files
        // addFile(protocol, protocolMeta, name, _hash, ext, encrypted, encryptedHash, groupIndex)
        addFile(1, "0x00", "index", "QmTecWfmvvsPdZXuYrLgCTqRj9YgBiAUL4ZCr9iwDnp9q7", "0x123", false, "", 0);
        addFile(1, "0x00", "family", "QmTecWfmvvsPdZXuYrLgCTqRj9YgBiAUL4ZCr9iwDnp9q7", "0x123", false, "", 0);
        addFile(1, "0x00", "myportrait", "QmTecWfmvvsPdZXuYrLgCTqRj9YgBiAUL4ZCr9iwDnp9q7", "0x123", false, "", 0);
        addFile(1, "0x00", "cutepic", "QmTecWfmvvsPdZXuYrLgCTqRj9YgBiAUL4ZCr9iwDnp9q7", "0x123", false, "", 0);
        addFile(1, "0x00", "awesome", "QmTecWfmvvsPdZXuYrLgCTqRj9YgBiAUL4ZCr9iwDnp9q7", "0x123", false, "", 0);
    }

    // Get Indexes with Names for EIN
    // _for = 1 is Files, 2 is GroupFiles, 3 is Groups
    function debugIndexesWithNames(uint _ein, uint _groupIndex, uint _seedPointer, uint16 _limit, bool _asc, uint8 _for)
    external view
    returns (uint[20] memory _indexes, string memory _names) {

        if (_for == 1) {
            _indexes = _getIndexes(fileOrder[_ein], _seedPointer, _limit, _asc);
        }
        else if (_for == 2) {
            _indexes = _getIndexes(groups[_ein][_groupIndex].groupFilesOrder, _seedPointer, _limit, _asc);
        }
        else if (_for == 3) {
            _indexes = _getIndexes(groupOrder[_ein], _seedPointer, _limit, _asc);
        }

        uint16 i = 0;
        bool completed = false;

        while (completed == false) {
            string memory name;

            // Get Name
            if (_for == 1 || _for == 2) {
                name = files[_ein][_indexes[i]].name;
            }
            else if (_for == 3) {
                name = groups[_ein][_indexes[i]].name;
            }

            // Add To Return Vars
            name = _append(name, "|");
            _names = _append(_names, name);

            i++;

            // check status
            if (i == _limit || (_indexes[i-1] == _indexes[i])) {
                completed = true;
            }
        }
    }
}
