// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "../lib/math/SafeMath.sol";
import "../lib/access/OwnableUpgradeable.sol";
import "../lib/verify/Verify.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/IRouter.sol";

contract PerpetualMachine is Verify{
    using SafeMath for uint256;
    IERC20 public _usdt;
    IERC20 public _uft;
    Verify public _vContract;
    address public _uftSender;
    address public _admin;

    uint8 public _revenueRatio;
    uint8 public _commissionRatio;

    IRouter public _router;
    IERC20 public _wkto;
    uint256 public _ktoDecimal;
    uint256 public _uftDecimal;
    uint256 public _usdtDecimal;

    event ParticipateWithUSDT(address user,uint256 uAmount,uint256 kAmount);
    event ClaimUsdt(address user,uint256 uAmount,uint256 uftAmount);
    event ClaimCommission_USDT(address user,uint256 uAmount,uint256 uftAmount);
    event ClaimMintedUft(address user,uint256 uftAmount);

    event ParticipateWithKTO(address user,uint256 amount);
    event ClaimKTO(address user,uint256 amount);
    event ClaimCommission_KTO(address user,uint256 amount);

    function initialize(address usdt,address uft,Verify vContract,address usender,address admin,address router,address wkto) public initializer {
        _usdt = IERC20(usdt);
        _uft= IERC20(uft);
        _vContract = vContract;
        _uftSender = usender;
        _admin = admin;
        _revenueRatio = 35;
        _commissionRatio = 35;
        _router = IRouter(router);
        _wkto = IERC20(wkto);
        _ktoDecimal = 1e11;
        _uftDecimal = 1e18;
        _usdtDecimal = 1e18;

        __Ownable_init();
    }

    function participateWithUsdt(uint256 uAmount,uint256 ulimit) external payable  returns (bool){
        require(uAmount >0,"Amount cant't be 0");
        require(ulimit > 0 ,"round limit is 0!");

        uint256 ktoAmount = usdtToKto(ulimit);
        require(msg.value.mul(1e7) >= ktoAmount,"ticket fee not enough!");

        require(
            _usdt.allowance(msg.sender,address(this)) >= uAmount,
            "spender allowance not enough!"
        );
        require(_usdt.balanceOf(msg.sender) >= uAmount,
            "user balance not enough!"
        );
        require(
            _usdt.transferFrom(msg.sender,address(this),uAmount),
            "participate transfer usdt failed!"
        ); 
        emit ParticipateWithUSDT(msg.sender,uAmount,ktoAmount);
        return true;
    }

    function claimUsdt (uint256 value,string calldata signTime, bytes32 signature,bool commission)external returns(bool){
        require(value > 0,"claim amount can't be 0!");
        //verify signature
        require(
            _vContract.verifySignature(value,signTime,msg.sender,signature),
            "claimUsdt verify signature failed!"
        );
        
        //消耗 35% UFT 手续费
        uint256 charge = serviceCharge(value,commission);  
        
        //领取value USDT
        require(_usdt.balanceOf(address(this)) >= value,
            "claimUsdt: usdt balance not enough!"
        );
        require(
            _usdt.transfer(msg.sender,value),
            "claimUsdt transfer usdt failed!"
        );
        if (commission){
            emit ClaimCommission_USDT(msg.sender,value,charge);
        }else{
            emit ClaimUsdt(msg.sender,value,charge);
        }
        return true;
    }
    function serviceCharge(uint256 value,bool commission)internal returns(uint256){
        require(value > 0,"claim amount can't be 0!");
        uint256 charge;
        if (commission){
            charge = value.mul(_commissionRatio).div(100);
        }else{
            charge = value.mul(_revenueRatio).div(100);
        }

        uint256 uftPrice = getTokenPrice(_uftDecimal,address(_uft),address(_usdt));
        uint256 uftAmount = charge.mul(_usdtDecimal).div(uftPrice);
        require(uftAmount > 0,"uft amount is 0!");
        
        require(
            _uft.allowance(msg.sender,address(this)) >= uftAmount,
            "serviceCharge spender uft allowance not enough!"
        );
        require(
            _uft.balanceOf(msg.sender) >= uftAmount,
            "serviceCharge Not enough handling fees!"
        );
        require(
            _uft.transferFrom(msg.sender,address(this),uftAmount),
            "serviceCharge transfer uft failed!"
        );
        return uftAmount;
    }

    function claimMintedUft(uint256 amount,string calldata signTime, bytes32 signature)external returns(bool){
        require(amount > 0,"claim amount can't be 0!");
        //verify signature
        require(
            _vContract.verifySignature(amount,signTime,msg.sender,signature),
            "claimMintedUft verify signature failed!"
        );
        if (_uft.balanceOf(address(this)) >= amount){
            require(
                _uft.transfer(msg.sender,amount),
                "claimMintedUft transfer uft failed!"
            );
        }else{
            require(
                _uft.allowance(_uftSender,address(this)) >= amount,
                "claimMintedUft spender uft allowance not enough!"
            );
            require(
                _uft.balanceOf(_uftSender) >= amount,
                "claimMintedUft Not enough uft balance!"
            );
            require(
                _uft.transferFrom(_uftSender,msg.sender,amount),
                "claimMintedUft transferFrom uft failed!"
            );
        }    
        emit ClaimMintedUft(msg.sender,amount);
        return true;
    }

    //withDraw USDT
    function withdrawUsdt()external onlyOwner returns(bool){
        uint256 balance = _usdt.balanceOf(address(this));
        require( balance > 0, "withdrawUsdt: usdt balance is 0");
        require(_admin != address(0),"admin is empty!");
        require(
            _usdt.transfer(_admin,balance),
            "withdrawUsdt transfer usdt failed!"
        );
        return true;
    }

    //withDraw UFT
    function withdrawUft()external onlyOwner returns(bool){
        uint256 balance = _uft.balanceOf(address(this));
        require( balance > 0, "withdrawUft: uft balance is 0");
        require(_admin != address(0),"admin is empty!");
        require(
            _uft.transfer(_admin,balance),
            "withdrawUsdt transfer usdt failed!"
        );
        return true;
    }

    function withdrawKto(uint256 amount)external onlyOwner returns(bool){
        require(address(this).balance >= amount,"not sufficient funds!");
        payable(_admin).transfer(amount);
    }
    
    function allowanceUsdt()external view returns(uint){
        return _usdt.allowance(msg.sender, address(this));
    }

    function allowanceUft()external view returns(uint){
        return _uft.allowance(msg.sender, address(this));
    }

    function setUsdtAddr(address usdt)external onlyOwner{
        _usdt = IERC20(usdt);
    }

    function setUftAddr(address uft)external onlyOwner{
        _uft = IERC20(uft);
    }
    
    function setAdmin(address adm) external onlyOwner{
        _admin = adm;
    }

    function setRevenueRatio(uint8 ratio) external onlyOwner{
        _revenueRatio = ratio;
    }
    function setCommissionRatio(uint8 ratio) external onlyOwner{
        _commissionRatio = ratio;
    }

    function setIRouter(address router) external onlyOwner{
        _router = IRouter(router);
    }

    /**
        @dev amount(带精度)个Token对应USDT数量
        token0: token address
        token
     */
    function getTokenPrice(uint256 amount,address token,address usdt) public view returns (uint256 price) {
        address[] memory path = new address[](2);
        path[0] = token;
        path[1] = usdt;
        uint256[] memory amounts = IRouter(_router).getAmountsOut(amount, path);
        return amounts[1];
    }

    function setWKtoAddress(address wkto) external onlyOwner{
        _wkto = IERC20(wkto);
    }

    function setKtoDecimal() external onlyOwner{
        _ktoDecimal = 1e11;
    }

    function setUftDecimal() external onlyOwner{
       _uftDecimal = 1e18;
    }

    function setUsdtDecimal() external onlyOwner{
       _usdtDecimal = 1e18;
    }

    function usdtToKto(uint256 uAmount) public view returns (uint256){
        uint256 charge = uAmount.div(100);
        uint256 ktoPrice = getTokenPrice(_ktoDecimal,address(_wkto),address(_usdt));
        return charge.mul(_usdtDecimal).div(ktoPrice);
    }
}