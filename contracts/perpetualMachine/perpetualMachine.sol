// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "../lib/math/SafeMath.sol";
import "../lib/access/OwnableUpgradeable.sol";
import "../lib/verify/Verify.sol";
import "../interfaces/IERC20.sol";

contract PerpetualMachine is Verify{
    using SafeMath for uint256;
    IERC20 public _usdt;
    IERC20 public _uft;
    Verify public _vContract;
    address public _uftSender;

    event Participate(address user,uint256 amount);
    event ClaimCommission(address user,uint256 amount);
    event ClaimUsdtRewards(address user,uint256 amount);

    function initialize(address usdt,address uft,Verify vContract,address usender) public initializer {
        _usdt = IERC20(usdt);
        _uft= IERC20(uft);
        _vContract = vContract;
        _uftSender = usender;
        
        __Ownable_init();
    }

    function participate(uint256 uAmount) external returns (bool){
        require(uAmount >0,"Amount cant't be 0");
        require(
            _usdt.allowance(msg.sender,address(this)) >= uAmount,
            "spender allowance not enough!"
        );
        require(_usdt.balanceOf(msg.sender) >= uAmount,
            "user balance not enough!"
        );
        require(
            _usdt.transferFrom(msg.sender,address(this),uAmount),
            "transfer usdt failed!"
        ); 
        emit Participate(msg.sender,uAmount);
        return true;
    }

    function claimUsdt (uint256 value,string calldata signTime, bytes32 signature,bool commission)external returns(bool){
        require(value > 0,"claim amount can't be 0!");
        //verify signature
        require(
            _vContract.verifySignature(value,signTime,msg.sender,signature),
            "verify signature failed!"
        );
        //消耗30%UFT 手续费
        if (commission){
            require(
                serviceCharge(value),
                "Claim Invite Commission failed!"
            );
        }
        //领取value USDT
        require(_usdt.balanceOf(address(this)) >= value,
            "contract usdt balance not enough!"
        );
        require(
            _usdt.transferFrom(address(this),msg.sender,value),
            "transfer usdt failed!"
        );
        if (commission){
            emit ClaimCommission(msg.sender,value);
        }else{
            emit ClaimUsdtRewards(msg.sender,value);
        }
        
        return true;
    }
    
    function serviceCharge(uint256 value)internal returns(bool){
        require(value > 0,"claim amount can't be 0!");
        uint256 charge = value.mul(30).div(100);
        require(
            _uft.allowance(msg.sender,address(this)) >= charge,
            "spender uft allowance not enough!"
        );
        require(
            _uft.balanceOf(msg.sender) >= charge,
            "Not enough handling fees!"
        );
        require(
            _uft.transferFrom(msg.sender,address(this),charge),
            "transfer uft failed!"
        );
        return true;
    }

    function claimMintUft(uint256 amount,string calldata signTime, bytes32 signature)external returns(bool){
        require(amount > 0,"claim amount can't be 0!");
        //verify signature
        require(
            _vContract.verifySignature(amount,signTime,msg.sender,signature),
            "verify signature failed!"
        );
        require(
            _uft.allowance(_uftSender,address(this)) >= amount,
            "spender uft allowance not enough!"
        );
        require(
            _uft.balanceOf(_uftSender) >= amount,
            "Not enough handling fees!"
        );
        require(
            _uft.transferFrom(_uftSender,msg.sender,amount),
            "transfer uft failed!"
        );
        return true;
    }
    //withDraw USDT
    //withDraw UFT
}