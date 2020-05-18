pragma solidity ^0.5.0;

interface IceInterface {
    function getGlobalItems(uint _index1, uint _index2) external view 
    returns (uint ownerEIN, uint itemRecord, bool isFile, bool isHidden, bool deleted, uint sharedToCount, uint stampingReqsCount);
    function getGlobalItemsMapping(uint _index1, uint _index2, uint8 _ofType, uint8 _mappedIndex) external view
    returns (uint mappedToEIN, uint atIndex);
    
    function getFileIndexes(uint _ein, uint _seedPointer, uint16 _limit, bool _asc) external view returns (uint[20] memory fileIndexes);
    function getFile(uint _ein, uint _fileIndex) external view
    returns (uint8 protocol, bytes memory protocolMeta, string memory name, string memory hash, bytes8 ext, uint32 timestamp, bool encrypted, uint associatedGroupIndex, uint associatedGroupFileIndex);
    function getFileTransferInfo(uint _ein, uint _fileIndex) external view 
    returns (uint transCount, uint transEIN, uint transIndex, bool forTrans);
    function getFileTransferOwners(uint _ein, uint _fileIndex, uint _transferIndex) external view returns (uint recipientEIN);
    function addFile(uint8 _protocol, bytes calldata _protocolMeta, string calldata _name, string calldata _hash, bytes8 _ext, bool _encrypted, string calldata _encryptedHash, uint _groupIndex) external;
    function changeFileName(uint _fileIndex, string calldata _name) external;
    function moveFileToGroup(uint _fileIndex, uint _newGroupIndex) external;
    function deleteFile(uint _fileIndex) external;
    
    function getGroupFileIndexes(uint _ein, uint _groupIndex, uint _seedPointer, uint16 _limit, bool _asc) external view returns (uint[20] memory groupFileIndexes);

    function getGroup(uint _ein, uint _groupIndex) external view returns (uint index, string memory name);
    function getGroupIndexes(uint _ein, uint _seedPointer, uint16 _limit, bool _asc) external view returns (uint[20] memory groupIndexes);
    function createGroup(string calldata _groupName) external;
    function renameGroup(uint _groupIndex, string calldata _groupName) external;
    function deleteGroup(uint _groupIndex) external;
    
    function shareItemToEINs(uint[] calldata _toEINs, uint _itemIndex, bool _isFile) external;
    function removeShareFromEINs(uint[32] calldata _toEINs, uint _itemIndex, bool _isFile) external;
    function removeSharingItemNonOwner(uint _itemIndex) external;
    
    function addToWhitelist(uint _nonOwnerEIN) external;
    function removeFromWhitelist(uint _nonOwnerEIN) external;
    function addToBlacklist(uint _nonOwnerEIN) external;
    function removeFromBlacklist(uint _nonOwnerEIN) external;
    
    
}