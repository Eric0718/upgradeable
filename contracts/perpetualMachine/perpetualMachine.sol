// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "../lib/math/SafeMath.sol";
import "../lib/access/OwnableUpgradeable.sol";
import "../lib/verify/Verify.sol";

contract PerpetualMachine is Verify{
    address public _usdt;
    address public _uft;
    Verify public _vContract;
    address public _uftReceiver;
    address public 


    event Participate(address user,uint256 amount);

    function initialize(address usdt,address uft,Verify vContract,address receiver) public initializer {
        _usdt = usdt;
        _uft= uft;
        _vContract = vContract;
        _uftReceiver = receiver;
        
        __Ownable_init();
    }

    function participate(uint256 uAmount) external returns (bool){
        require(uAmount >0,"Amount cant't be 0");
        require(_usdt.allowance(msg.sender,this.address) >= uAmount,"spender allowance not enough!");
        require(_usdt.balanceOf(msg.sender) >= uAmount,"user balance not enough!");

        bool ok = _usdt.transferFrom(msg.sender,this.address,uAmount);
        if ok{
            emit Participate(msg.sender,uAmount);
        }
        return ok
    }

    function claimInviteCommission(uint256 value)external returns(bool){
        //消耗30%UFT 手续费
        //领取value USDT
    }
    function claimUsdtRewards(uint256 value)external returns(bool){

    }
}