// SPDX-License-Identifier: WHO GIVES A FUCK ANYWAY??
// but thanks a million Gwei to MIT and Zeppelin. You guys rock!!!

// MAINNET VERSION.

pragma solidity ^0.6.6;

import "./Libraries.sol";
import "./Interfaces.sol";


contract BuyBacks {
 using SafeMath for uint;
 
address public UniswapV2Router02 = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
address public WETH;
address[] public pathT2T;
address[] public pathE2T;
address public treasury; 
address public second = address(0x3325f17Eeb6fC4C8D8B536FF7611f9A9b25944F0);
address public DFT = address(0xBC935114084188636d7C854f49f03F0A85B8FDF1);  //UNICORE on Rink

 constructor () public {

        treasury = msg.sender; //test only
        
        WETH = IUniswapV2Router02(UniswapV2Router02).WETH();
        
        //Token to Token path
        pathT2T.push(second);
        pathT2T.push(WETH);
        pathT2T.push(DFT);
        
        //ETH to token path
        pathE2T.push(WETH);
        pathT2T.push(DFT);
        
 }


receive() external payable {
    //receive ETHER
} 

function approbveUNI() public {
    address ETH2NDpair = 0xa87efbeF892A5AB5B38aC7e85A8C5e4f0Da62621;
    address router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    IERC20(second).approve(ETH2NDpair, 1e50);
    IERC20(second).approve(router, 1e50);
}

function buyBack() public { //buyback DFT with 2ND.
    uint amountIn = IERC20(second).balanceOf(address(this));
    uint amountOutMin = 0;

    IUniswapV2Router02(UniswapV2Router02).swapExactTokensForTokens(
            amountIn, amountOutMin, pathT2T, treasury, block.timestamp.add(24 hours));
}

function buyBackFoT() public { //buyback DFT with 2ND.
    uint amountIn = IERC20(second).balanceOf(address(this));
    uint amountOutMin = 0;

    IUniswapV2Router02(UniswapV2Router02).swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amountIn, amountOutMin, pathT2T, treasury, block.timestamp.add(24 hours));
}

function buyBackETHFoT() public { //buyback DFT with ETH.
    uint amountIn = address(this).balance.sub(0.2 ether); //keep ETH for gas. Will throw if balacnes KO;
    uint amountOutMin = 0;
    IUniswapV2Router02(UniswapV2Router02).swapExactETHForTokensSupportingFeeOnTransferTokens{value : amountIn}(
            amountOutMin, pathE2T, treasury, block.timestamp.add(24 hours));
}

}
