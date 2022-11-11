// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "../lib/math/SafeMath.sol";
import "../lib/access/OwnableUpgradeable.sol";

contract Collect is OwnableUpgradeable{
    using SafeMath for uint256;
    uint256 public _baseValue;
    uint256 private _decimal;
    address public _community;
    address public _technical;
    address public _devAddress;

    // uint256 public recommendedRatio;    //20%
    // uint256 public performanceRatio;    //20%
    // uint256 public teamCoachingRatio;   //5%
    // uint256 public communityGiftRatio;  //50%
    // uint256 public communityNodeRatio;  //5%


    struct rewardsInfo{
        uint256 directRecommended;
        uint256 directClaimed;
        uint256 indirectRecommended;
        uint256 indirectClaimed;
        uint256 totalRewards;
    }

    struct inviteInfo{
        uint256 directMembers;
        uint256 indirectMembers;
    }

    struct inputInfo{
        uint256 baseInput;
        uint256 totalReinput;
    }

    mapping(address => bool) _commonUser;
    mapping(address => bool) _officialUser;
    mapping(address => bool) _communityNode;
    mapping(address => address) _inviteRelationship;
    mapping(address => rewardsInfo) _rewardsInfos;
    mapping(address => inviteInfo) _inviteInfos;
    mapping(address => inputInfo) _inputInfos;

    //evnets
    event Participate(address participant,address inviter,uint256 amount);
    event Reinput(address user,uint256 amount);
    event Claim(address user,uint256 amount);

    function initialize(address community,address technical,address devAddress) public initializer {
        _decimal = 1e11;
        _baseValue = uint256(1030).mul(_decimal);
        _community = community;
        _technical = technical;
        _devAddress = devAddress;
    }

    // function register() external{
    //     _commonUser[msg.sender] = true;
    // }

    function participate(address inviter) external payable{
        //require(_commonUser[msg.sender],"User is not registered!");
        require(inviter != address(0),"Invalid inviter address!");
        require(msg.value == _baseValue,"participate value not enough!");
        require(address(this).balance >= uint256(30).mul(_decimal),"Not enough amount!");
        require(_inviteRelationship[msg.sender] == address(0),"User already participated!");

        _officialUser[msg.sender] = true;
        _inviteRelationship[msg.sender] = inviter;
        _inputInfos[msg.sender].baseInput  = uint256(1000).mul(_decimal);

        // recommendedRatio += _inputInfos[msg.sender].baseInput .mul(20).div(100);
        // performanceRatio += _inputInfos[msg.sender].baseInput .mul(20).div(100);
        // teamCoachingRatio += _inputInfos[msg.sender].baseInput .mul(5).div(100);
        // communityGiftRatio += _inputInfos[msg.sender].baseInput .mul(50).div(100);
        // communityNodeRatio += _inputInfos[msg.sender].baseInput .mul(5).div(100);

        //direct recommendation
        _inviteInfos[inviter].directMembers += 1;
        _rewardsInfos[inviter].directRecommended += _inputInfos[msg.sender].baseInput.mul(10).div(100);

        //indirect recommendation
        _inviteInfos[_inviteRelationship[inviter]].indirectMembers += 1;
        _rewardsInfos[_inviteRelationship[inviter]].indirectRecommended += _inputInfos[msg.sender].baseInput.mul(10).div(100);

        payable(_community).transfer(uint256(15).mul(_decimal));
        payable(_technical).transfer(uint256(15).mul(_decimal));
        emit Participate(msg.sender,inviter,_baseValue);
    }

    function reinput(uint256 amount/* singnature */) external{
        require(_officialUser[msg.sender] || _communityNode[msg.sender],"Only participant can reinput!");
        //verify sign
        _reinput(amount);
        _inputInfos[msg.sender].totalReinput += amount;
        emit Reinput(msg.sender,amount);
    }

    function _reinput(uint256 amount) internal{
         require(amount >= uint256(100).mul(_decimal),"Amount can't be < 100!");
         require(amount.mod(uint256(100).mul(_decimal)) == 0,"Amount can't be < 100!");

        _inputInfos[msg.sender].baseInput = amount;

        // recommendedRatio += _inputInfos[msg.sender].baseInput .mul(20).div(100);
        // performanceRatio += _inputInfos[msg.sender].baseInput .mul(20).div(100);
        // teamCoachingRatio += _inputInfos[msg.sender].baseInput .mul(5).div(100);
        // communityGiftRatio += _inputInfos[msg.sender].baseInput .mul(50).div(100);
        // communityNodeRatio += _inputInfos[msg.sender].baseInput .mul(5).div(100);

        address inviter = _inviteRelationship[msg.sender];
        _rewardsInfos[inviter].directRecommended += _inputInfos[msg.sender].baseInput.mul(10).div(100);
        _rewardsInfos[_inviteRelationship[inviter]].indirectRecommended += _inputInfos[msg.sender].baseInput.mul(10).div(100);
    }

    function claimRewards(uint256 claimValue /* singnature */) external{
        require(claimValue > 0,"claim amount can't be 0!");
        require(_officialUser[msg.sender] || _communityNode[msg.sender],"Only participant can claimRewards!");
        require(address(this).balance >= claimValue,"not sufficient funds!");

        //verify sign
        _rewardsInfos[msg.sender].directClaimed += _rewardsInfos[msg.sender].directRecommended;
        _rewardsInfos[msg.sender].directRecommended = 0;
        _rewardsInfos[msg.sender].indirectClaimed += _rewardsInfos[msg.sender].indirectRecommended;
        _rewardsInfos[msg.sender].indirectRecommended = 0;
        payable(msg.sender).transfer(claimValue);
        _rewardsInfos[msg.sender].totalRewards += claimValue;
       emit Claim(msg.sender,claimValue);
    }

    function applyForCommunityNode()external{
        require(_officialUser[msg.sender],"User must be a official user!");
        require(_inputInfos[msg.sender].totalReinput >= uint256(1000).mul(_decimal),"totalReinput value must be over 1000 KTO!");
        _communityNode[msg.sender] = true;
    }

    function withdraw(uint256 amount) public onlyOwner{
        require(address(this).balance >= amount,"not sufficient funds!");
        payable(_devAddress).transfer(amount);
    }

    function setBaseValue(uint256 value) external onlyOwner{
        _baseValue = value;
    }

    function getUserState()external view returns(uint8){
        if(_officialUser[msg.sender]){
            return 1;
        }else if(_communityNode[msg.sender]){
            return 2;
        }
        return 0;
    }

    function getRewardsInfo()external view returns(uint256 direct,uint256 indirect,uint256 total){
        return (_rewardsInfos[msg.sender].directClaimed,_rewardsInfos[msg.sender].indirectClaimed,_rewardsInfos[msg.sender].totalRewards);
    }

    function getTotalReinput()external view returns(uint256){
        return _inputInfos[msg.sender].totalReinput;
    }

    function getInviteMembers() external view returns(uint256 direct,uint256 indirect){
        return (_inviteInfos[msg.sender].directMembers,_inviteInfos[msg.sender].indirectMembers);
    }
}
