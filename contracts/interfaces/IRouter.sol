// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

interface IRouter {
    /**
    @dev 调用swap的方法，根绝指定代币的输入量，返回通过path路径交易之后的输出代币数量
    @param  amountIn    输入代币数量
    @param  path        交易代币路径，比如[token,usdt]
    @return amounts     输出代币数量数组，数组索引与代币路径对应,[0:token支出数量,1:usdt获得数量]
     */
    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}