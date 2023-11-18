// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// ERC20 token interface
interface Token {
    function transfer(address _to, uint256 _value) external returns (bool);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool);
    function allowance(address _owner, address _spender) external view returns (uint256);
}
//Note that every amount transferred to this contract must be in WEI, wether you want to withdraw or update or send, it must be in WEI
contract Multisend {
    event NewPayment(
        uint256 indexed date,
        address from,
        address[] indexed to,
        uint256[] indexed amount
    );

    address public owner;
    uint256 public sendTokenFee;
    uint256 public sendEthFee;

    constructor() {
        owner = msg.sender;
    }

    receive() external payable {}

    function multiSendEther(address[] calldata addresses, uint256[] calldata amounts) external payable returns (bool) {
        require(addresses.length == amounts.length, "Unbalanced addresses and amounts");
        require(addresses.length > 0, "No recipients");
        require(msg.value > 0, "Amount must be greater than 0");
        require(msg.value >= sendEthFee, "Insufficient ETH sent for fees");
        address sender = msg.sender;
        uint256 total = 0;

        for (uint256 n = 0; n < addresses.length; n++) {
            total += amounts[n];
        }

        uint256 requiredAmount = total + sendEthFee;

        require(msg.value >= requiredAmount, "Insufficient ETH sent");

        for (uint256 n = 0; n < addresses.length; n++) {
            require(addresses[n] != address(0), "Invalid recipient address");
            require(addresses[n] != sender, "You cannot pay yourself");
            payable(addresses[n]).transfer(amounts[n]);
        }

        if (msg.value > requiredAmount) {
            uint256 change = msg.value - requiredAmount;
            payable(sender).transfer(change);
        }
        payable(address(this)).transfer(sendEthFee);
        emit NewPayment(block.timestamp, sender, addresses, amounts);

        return true;
    }

    function multiSendToken(address tokenAddress, address[] calldata addresses, uint256[] calldata amounts) external payable returns (bool) {
        address sender = msg.sender;
        uint256 total = 0;
        uint256 valueSent = msg.value;

        for (uint256 n = 0; n < addresses.length; n++) {
            total += amounts[n];
        }

        uint256 requiredWeiAmount = sendTokenFee;

        require(valueSent >= requiredWeiAmount, "Insufficient ETH sent");

        require(Token(tokenAddress).allowance(sender, address(this)) >= total, "Token allowance too low");

        for (uint256 n = 0; n < addresses.length; n++) {
            require(Token(tokenAddress).transferFrom(sender, addresses[n], amounts[n]), "Token transfer failed");
        }

        if (valueSent > requiredWeiAmount) {
            uint256 change = valueSent - requiredWeiAmount;
            payable(sender).transfer(change);
        }

        return true;
    }

    function withdrawEther(uint256 _value) external returns (bool) {
        require(msg.sender == owner, "Only owner can call this function");
        payable(owner).transfer(_value);
        return true;
    }

    function withdrawToken(address tokenAddress, uint256 _value) external returns (bool) {
        require(msg.sender == owner, "Only owner can call this function");
        require(Token(tokenAddress).transfer(owner, _value), "Token transfer failed");
        return true;
    }

    function setSendTokenFee(uint256 _sendTokenFee) external returns (bool) {
        require(msg.sender == owner, "Only owner can call this function");
        sendTokenFee = _sendTokenFee;
        return true;
    }

    function setSendEthFee(uint256 _sendEthFee) external returns (bool) {
        require(msg.sender == owner, "Only owner can call this function");
        sendEthFee = _sendEthFee;
        return true;
    }

}
