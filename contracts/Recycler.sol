  
// SPDX-License-Identifier: WHO GIVES A FUCK ANYWAY??
// but thanks a million Gwei to MIT and Zeppelin. You guys rock!!!

// MAINNET VERSION.

pragma solidity ^0.6.6;

import "./ERC20.sol";

//Liquidity Token Wrapper

contract Recycler is ERC20 {
    using SafeMath for uint256;
    using Address for address;

    address public secondChance;
    address public UNIv2;
    address private owner;


    modifier onlySecondChance{
        require(msg.sender == secondChance, "Only UniCore can send wrapped tokens");
        _;
    }
//=========================================================================================================================================
    constructor() ERC20("Wrapped2NDLP", "RE") public {
        owner = msg.sender;
    }
    
    function initialize(address _secondChance) public {
        require(msg.sender == owner);
        wrappingRatio = 100;
        secondChance = _secondChance;
        UNIv2 = ISecondChance(secondChance).viewUNIv2();
        require(secondChance != address(0) && UNIv2 != address(0));
    }

//=========================================================================================================================================
    //WUNIv2 minter
    function _wrapUNIv2(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        //transferFrom UNIv2
        ERC20(UNIv2).transferFrom(sender, recipient, amount); //sends UNIv2 to recipient (secondChance token)
        
        //Mint Tokens, equal to the UNIv2 amount sent
        _mint(sender, amount.mul(wrappingRatio).div(100));
        
        //sendToFarm(); //disabled for testing
        postWrapBurnfromUNI();

    }
    
    function postWrapBurnfromUNI() public {
        uint256 burnRate = ISecondChance(secondChance).viewBurnOnTx();
        uint256 toBurnFromUni = ERC20(secondChance).balanceOf(UNIv2).mul(burnRate).div(1000);
        ISecondChance(secondChance).burnFromUni(toBurnFromUni); //create a small burn (0.05% of supply)
    }
    
    //Allows user to wrap UNIv2 tokens
    uint256 private wrappingRatio;
    
    function wrapUNIv2(uint256 amount) public {
        require(wrappingRatio > 0, "Wrapping ratio cannot be zero");
        _wrapUNIv2(msg.sender, secondChance, amount);
    }

    
//=========================================================================================================================================
    //allows ANYBODY to load the rewards on this token to the DeFiat farm.
    //Seaparated from the 2ND _transfer function to save gas. (bulk sends).
    //Triggered every time someone WRAPS
    function sendToFarm() public {
        address farm = ISecondChance(secondChance).viewFarm();
        IFarm(farm).loadRewards(balanceOf(address(this)), 0); //updating the vault with rewards sent.
    }
    

 //=========================================================================================================================================
    function setWrappingRatio(uint256 _ratioBase100) external onlySecondChance {
        require(_ratioBase100 <= 100, "wrappingRatio capped at 100%");
        wrappingRatio = _ratioBase100;
    }
    function viewWrappingRatio() public view returns(uint256)  {
        return wrappingRatio;
    }
    

}
