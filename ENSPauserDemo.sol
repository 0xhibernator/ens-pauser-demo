// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./ENSNamehash.sol";

// Get the required fundtions from the ENS and Resolver contracts
abstract contract ENS {
    function resolver(bytes32 node) public virtual view returns (Resolver);
}

abstract contract Resolver {
    function addr(bytes32 node) public virtual view returns (address);
}

contract ENSPauserDemo is ERC20, Ownable, Pausable {
    // Same address for Mainet, Ropsten, Rinkerby, Gorli and other networks;
    ENS ens = ENS(0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e);
    bytes32 internal _pauserNamehash;

    // Set the pauser namehash based on the ENS name at initialization
    constructor(string memory _name) ERC20("ENSPausable", "ENSP") {
        _pauserNamehash = computeNamehash(_name);
    }

    // Check the message sender against the ENS name resolution of the pauser namehash
    modifier onlyPauser {
        require(msg.sender == resolvePauser(), "Not allowed to pause");
        _;
    }

    using ENSNamehash for bytes;

    // Compute the namehash of an ENS name
    function computeNamehash(string memory _name)
        private
        pure
        returns (bytes32 namehash)
    {
        return bytes(_name).namehash();
    }

    // Resolve the ENS name based on the namehash
    function resolvePauser()
        private 
        view 
        returns (address) 
    {
        Resolver resolver;
        resolver = Resolver(ens.resolver(_pauserNamehash));
        return resolver.addr(_pauserNamehash);
    }

    // Return the namehash for the ENS name set as the pauser
    function getPauser() 
        public 
        view 
        returns (bytes32) 
    {
        return _pauserNamehash;
    }

    // Set the pauser namehash based on the ENS name
    function setPauser(string memory _name)
        public 
        onlyOwner  
    {
        _pauserNamehash = computeNamehash(_name);
    }

    //Pausable functions
    function pause() public onlyPauser {
        _pause();
    }

    function unpause() public onlyPauser {
        _unpause();
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, amount);
    }
}