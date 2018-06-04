pragma solidity ^0.4.18;

import "./BulleonToken.sol";

contract BulleonMultitransfer is Claimable {
    address public BulleonAddress;
    address public sender;
    BulleonToken bulleon;

    /**
     * @dev Implements transfer method for multiple recipient. Needed in LBRS token distribution process after ICO
     * @param recipient - recipient addresses array
     * @param balance - refill amounts array
     */
    function multiTransfer(address[] recipient,uint256[] balance) public {
        require(recipient.length == balance.length && msg.sender == sender);

        for (uint256 i = 0; i < recipient.length; i++) {
            bulleon.transfer(recipient[i],balance[i]);
        }
    }

    /**
     * @dev Constructor
     */
    constructor (address token, address _sender) public {
        sender = _sender;
        bulleon = BulleonToken(token);
    }

    /**
     * @dev Withdraw unsold tokens
     */
    function withdrawTokens() public onlyOwner {
        bulleon.transfer(owner, tokenBalance());
    }

    /**
     * @dev Returns LBRS token balance of contract.
     */
    function tokenBalance() public view returns(uint256) {
        return bulleon.balanceOf(this);
    }

     /**
     * @dev Sets new token sender address
     * @param _sender - token sender addresses
     */
    function setSender(address _sender) public onlyOwner {
        sender = _sender;
    }

    /**
     * @dev Kill contracts after ICO.
     */
    function kill() public onlyOwner {
        withdrawTokens();
        selfdestruct(owner);
    }
}
