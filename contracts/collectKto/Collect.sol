// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "../lib/math/SafeMath.sol";
import "../lib/access/OwnableUpgradeable.sol";
import "../lib/verify/Verify.sol";

contract Collect is Verify{
    using SafeMath for uint256;
    uint256 public _baseValue;
    uint256 private _decimal;
    address public _community;
    address public _technical;
    address public _devAddress;

    mapping(address => address) _inviteRelationship; 
    
    uint256 public _baseReward;
    uint256 public _reinputModBase;
    uint256 public _reinputLimit;
    Verify public _vContract;

    //evnets
    event Participate(address participant,address inviter,uint256 amount);
    event Claim(address user,uint256 amount,bytes32 signature);

    function initialize(address community,address technical,address devAddress,Verify vContract) public initializer {
        _decimal = 1e11;
        _community = community;
        _technical = technical;
        _devAddress = devAddress;
        _baseValue = uint256(1).mul(_decimal); //1030
        _baseReward = uint256(1).mul(_decimal);//30
        _vContract = vContract;
        
        __Ownable_init();
        _vContract.initialize();
    }

    function participate(address inviter) external payable{
        require(inviter != address(0),"Invalid inviter address!");
        require(msg.value == _baseValue,"participate value not wright!");
        require(address(this).balance >= _baseReward,"balance Not enough amount!");
        //require(_inviteRelationship[msg.sender] == address(0),"User already participated!");

        _inviteRelationship[msg.sender] = inviter;
       
        require(_baseReward > 0);
        payable(_community).transfer(_baseReward.div(2));
        payable(_technical).transfer(_baseReward.div(2));
        emit Participate(msg.sender,inviter,msg.value);
    }

    function claimRewards(uint256 claimValue,string calldata signTime, bytes32 signature) external{
        require(claimValue > 0,"claim amount can't be 0!");
        require(address(this).balance >= claimValue,"not sufficient funds!");

        //verify signature
        bool ok = Verify.verifySignature(claimValue,signTime,msg.sender,signature);
        if (!ok){
            revert("verify signature failed!");
        }
        payable(msg.sender).transfer(claimValue);
        emit Claim(msg.sender,claimValue,signature);
    }

    function withdraw(uint256 amount) public onlyOwner{
        require(amount > 0,"not sufficient funds!");
        payable(_devAddress).transfer(amount);
    }

    function setBaseValue(uint256 value) external onlyOwner{
        _baseValue = value;
    }

    function setBaseReward(uint256 baseReward) external onlyOwner{
        _baseReward = baseReward;
    }

    function verify(uint256 amount, string calldata signTime, bytes32 signature)external view returns(bool) {
        return _vContract.verifySignature(amount,signTime,msg.sender,signature);
    }
    function setVContract(Verify vContract)external onlyOwner{
        _vContract = vContract;
    }
    function getTotalRewards()external view returns(uint256) {
        return address(this).balance;
    }
}
