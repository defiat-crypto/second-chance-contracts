// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./ERC20.sol";

contract Second_Chance is ERC20 { 

    using SafeMath for uint;

//== Variables ==
    address payable owner;     // token creator.

    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    
    
    uint256 public contractInitialized;
        
        
    bool openBar;
    
    //External addresses
    IUniswapV2Router02 public uniswapRouterV2;
    IUniswapV2Factory public uniswapFactory;
    
    address public uniswapPair; //to determine.
    address public recycler;
    address public farm;
    address public constant DFTToken = address(0xB6eE603933E024d8d53dDE3faa0bf98fE2a3d6f1);
    
    //Swapping metrics
    mapping(address => bool) public whitelist;
    uint256 public ETHfee;    
    uint256 public DFTRequirement; 
    
    //TX metrics
    mapping (address => bool) public noFeeList;

    uint256 public feeOnTx;
    uint256 public burnOnTx;


        
//== Modifiers ==
    
    modifier onlyOwner {
        if(openBar == false){require(msg.sender == owner, "only Mastermind");}
        _;
    }
    modifier whitelisted(address _token) {
        require(whitelist[_token] == true, "This token is not swappable");
        _;
    }
    modifier restricted() {
        require(msg.sender == owner || msg.sender == recycler, "function restricted");
        _;
    }
    
    
// ============================================================================================================================================================

    constructor() public ERC20("2ndChance", "2ND") {  //token requires that governance and points are up and running
        owner = msg.sender;
        DFTRequirement = 0; //disabled at launch 
        
        openBar = true; //to REMOVE in production
    }
    
    function initialSetup(address _recycler, address _farm) public payable onlyOwner {
        require(msg.value >= 1*1e18, "min 1 ETH to LGE");
        
        contractInitialized = block.timestamp;
        setTXandBURNFees(10, 10); //1% on buy on UNI, 0.1% uniBurn when wrapped
        ETHfee = 5*1e16; //0.05 EHT
        
        recycler = _recycler;
        noFeeList[recycler] = true;
        
        farm = _farm;
        noFeeList[farm] = true;
 
        CreateUniswapPair(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D, 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
        //0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D = UniswapV2Router02
        //0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f = UniswapV2Factory
        
        LGE();
    }
    
    //Pool UniSwap pair creation method (called by  initialSetup() )
    function CreateUniswapPair(address router, address factory) internal returns (address) {
        require(contractInitialized > 0, "Requires intialization 1st");
        
        uniswapRouterV2 = IUniswapV2Router02(router != address(0) ? router : 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapFactory = IUniswapV2Factory(factory != address(0) ? factory : 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f); 
        require(uniswapPair == address(0), "Token: pool already created");
        
        uniswapPair = uniswapFactory.createPair(address(uniswapRouterV2.WETH()),address(this));
        
        return uniswapPair;
    }
    
    function LGE() internal {
        ERC20._mint(address(this), 1e18 * 100); //pre-mine 100 tokens to UniSwap -> 1st UNI liquidity
        uint256 _amount = address(this).balance;
        
        IUniswapV2Pair pair = IUniswapV2Pair(uniswapPair);
        
        //Wrap ETH
        address WETH = uniswapRouterV2.WETH();
        IWETH(WETH).deposit{value : _amount}();
        
        //send to UniSwap
        require(address(this).balance == 0 , "Transfer Failed");
        IWETH(WETH).transfer(address(pair),_amount);
        
        //UniCore balances transfer
        ERC20._transfer(address(this), address(pair), balanceOf(address(this)));
        pair.mint(address(this));       //mint LP tokens. locked here... no rug pull possible
        
        IUniswapV2Pair(uniswapPair).sync();
    }   

// ============================================================================================================================================================
    function swapfor2NDChance(address _ERC20swapped, uint256 _amount) public payable {
        
        require(msg.value >= ETHfee, "pls add ETH in the payload");
        //require(ERC20(DFTToken).balanceOf(msg.sender) >= DFTRequirement, "Need to hold DFT to swap");  //KO if DFT not contract
        require(whitelist[_ERC20swapped] || openBar, "Token not swappable");
   
        sendETHtoUNI(); //bumps price, adds liquidity
        
        takeShitCoins(_ERC20swapped, _amount); // basic transferFrom
        
        uint256 _toMint = toMint(_ERC20swapped, _amount);
        mintChances(msg.sender, _toMint);
    }
    
    
    
    
// ============================================================================================================================================================    

    /* @dev mints function gives you a %age of the already minted 2nd
    * this %age is proportional to your %holdings of Shitcoin tokens
    */
    function toMint(address _ERC20swapped, uint256 _amount) public view returns(uint256){
        require(ERC20(_ERC20swapped).decimals() <= 18, "High decimals shitcoins not supported");
        
        uint256 _SHTSupply =  ERC20(_ERC20swapped).totalSupply();
        uint256 _SHTswapped = _amount.mul(1e24).div(_SHTSupply); //1e24 share of swapped tokens, max = 100%
        
        return _SHTswapped.mul(1000).div(1e24).mul(1e18); //holding 1% of the shitcoins gives you '10' 2ND tokens
    }
 
 
    
// ============================================================================================================================================================    


// NEED TO PASS ALL OF THESE AS INTERNAL FOR PRODUCTION

    function sendETHtoUNI() public {
        uint256 _amount = address(this).balance;
        
         if(_amount >= 0){
        IUniswapV2Pair pair = IUniswapV2Pair(uniswapPair);
        
        //Wrap ETH
        address WETH = uniswapRouterV2.WETH();
        IWETH(WETH).deposit{value : _amount}();
        
        //send to UniSwap
        require(address(this).balance == 0 , "Transfer Failed");
        IWETH(WETH).transfer(address(pair),_amount);
        
        IUniswapV2Pair(uniswapPair).sync();
        }
    }   //adds liquidity, bumps price.
    
    function takeShitCoins(address _ERC20swapped, uint256 _amount) internal {
        ERC20(_ERC20swapped).transferFrom(msg.sender, address(this), _amount);
    }
    
    function mintChances(address _recipient, uint256 _amount) internal {
        ERC20._mint(_recipient, _amount);
    }
    
    function burnFromUni(uint256 _amount) internal restricted {
        ERC20._burn(uniswapPair, _amount);
        IUniswapV2Pair(uniswapPair).sync();
    }
    

//=========================================================================================================================================
    //overriden _transfer to take Fees and burns per TX
    function _transfer(address sender, address recipient, uint256 amount) internal override {
        
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
    
        //updates _balances (low level call on modified ERC20 code)
        setBalance(sender, balanceOf(sender).sub(amount, "ERC20: transfer amount exceeds balance"));

        //calculate net amounts and fee
        (uint256 toAmount, uint256 toFee) = calculateAmountAndFee(sender, amount);
        
        //Send Reward to Farm 1st
        if(toFee > 0){
            setBalance(recycler, toFee);  //Recycler receieves 2ND chances tokens
            emit Transfer(sender, recycler, toFee);
        }

        //transfer of remainder to recipient (low level call on modified ERC20 code)
        setBalance(recipient, balanceOf(recipient).add(toAmount));
        emit Transfer(sender, recipient, toAmount);

    }
    
    function calculateAmountAndFee(address sender, uint256 amount) public view returns (uint256 netAmount, uint256 fee){

        if(noFeeList[sender]) { fee = 0;} // Don't have a fee when FARM is paying, or infinite loop
        else { fee = amount.mul(feeOnTx).div(1000);}
        
        netAmount = amount.sub(fee);
    }
   
    
//=========================================================================================================================================    
//ONLY_OWNER (ultra basic governance)

    function setTXandBURNFees(uint256 _txFee, uint256 _burnOnTx) public onlyOwner {
        feeOnTx = _txFee;
        burnOnTx = _burnOnTx;
    }
    function setDFTRequirement(uint256 _req) public onlyOwner {
        DFTRequirement = _req;
    }
    function setWrappingRatio(uint256 _ratioBase100) public onlyOwner {
        IRecycler(recycler).setWrappingRatio(_ratioBase100);
    }
   
    function whiteListToken(address _token, bool _bool) public onlyOwner {
        setOpenBar(false);
        whitelist[_token] = _bool;
    }
    function setNoFeeList(address _address) public onlyOwner {
        noFeeList[_address] = true;
    }
    function setOpenBar(bool _bool) public onlyOwner {
        openBar = _bool; //any Token is swappable. For tests only.
    }
    
    function setUNIV2(address _UNIV2) public onlyOwner {
        uniswapPair = _UNIV2;
    }
    


//GETTERS
    function viewUNIv2() public view returns(address) {
        return uniswapPair;
    }
    function viewFarm() public view returns(address) {
        return farm;
    }
    function viewFeeOnTx() public view returns(uint256) {
        return feeOnTx;
    }
    function viewBurnOnTx() public view returns(uint256) {
        return burnOnTx;
    }
    
    
    
//testing
    function getTokens(address _ERC20address) external onlyOwner {
        require(_ERC20address != uniswapPair, "cannot remove Liquidity Tokens");
        uint256 _amount = IERC20(_ERC20address).balanceOf(address(this));
        IERC20(_ERC20address).transfer(owner, _amount); //use of the _ERC20 traditional transfer
    }
    function kill() external onlyOwner {
        selfdestruct(msg.sender); //TESTNET onlyOwner
    }
    
}

contract SHITCOIN is ERC20 {
    constructor() public ERC20("ShitCoin", "SHIT") {  //token requires that governance and points are up and running
        ERC20._mint(address(0xde34854f9c81f126bC8a06850a00FC12a33db075),1e18 * 900);
        ERC20._mint(msg.sender, 1e18 * 100); //pre-mine 100 tokens to UniSwap -> 1st UNI liquidity
    }
}
