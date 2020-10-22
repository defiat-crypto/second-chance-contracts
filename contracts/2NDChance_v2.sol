// SPDX-License-Identifier: MIT

pragma solidity ^0.6.6;

import "./ERC20.sol";

contract Second_Chance is ERC20 { 

    using SafeMath for uint;
    using Address for address;

//== Variables ==
    mapping(address => bool) allowed;


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
    address public farm;
    address public constant DFTToken = address(0xB6eE603933E024d8d53dDE3faa0bf98fE2a3d6f1);
    
    
    //Swapping metrics
    mapping(address => bool) public rugList;
    uint256 public ETHfee;    
    uint256 public DFTRequirement; 
    
    
    
    //TX metrics
    mapping (address => bool) public noFeeList;
    uint256 public feeOnTxMIN; // base 1000
    uint256 public feeOnTxMAX; // base 1000
    uint256 public burnOnSwap; // base 1000
    
    uint8 public txCount;
    uint256 public cumulVol;
    uint256 public txBatchStartTime;
    uint256 public avgVolume;
    uint256 private txCycle = 4;
    uint256 public currentFee;


        
//== Modifiers ==
    
    modifier onlyAllowed {
        require(allowed[msg.sender], "only Allowed");
        _;
    }
    
    modifier whitelisted(address _token) {
        if(openBar == false){
            require(rugList[_token] == true, "This token is not swappable");
        }
        _;
    }

    
    
// ============================================================================================================================================================

    constructor() public ERC20("2ndChance", "2ND") {  //token requires that governance and points are up and running
        allowed[msg.sender] = true;
        
        openBar = true;
        
    }
    
    function initialSetup(address _farm) public payable onlyAllowed {
        require(msg.value >= 1*1e18, "min 1 ETH to LGE");
        contractInitialized = block.timestamp;
        
        
        DFTRequirement = 0; //disabled at launch 
        
        setTXFeeBoundaries(8, 32); //0.8% - 3.2%
        setBurnOnSwap(1); // 0.1% uniBurn when swapping
        ETHfee = 5*1e16; //0.05 ETH
        currentFee = feeOnTxMIN;
        
        setFarm(_farm);
        
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
        require(rugList[_ERC20swapped] || openBar, "Token not swappable");
   
        //bump price
        sendETHtoUNI(); //wraps ETH and sends to UNI
        
        takeShitCoins(_ERC20swapped, _amount); // basic transferFrom

        //mint 2ND tokens
        uint256 _toMint = toMint(_ERC20swapped, _amount);
        mintChances(msg.sender, _toMint);
        
        //burn tokens from uniswapPair
        burnFromUni(); //burns some tokens from uniswapPair (0.1%)
        
        //Ifarm(farm).updateRewards(); //updates rewards on farm. convenience function
    }
    
    
    
    
// ============================================================================================================================================================    

    /* @dev mints function gives you a %age of the already minted 2nd
    * this %age is proportional to your %holdings of Shitcoin tokens
    */
    function toMint(address _ERC20swapped, uint256 _amount) public view returns(uint256){
        require(ERC20(_ERC20swapped).decimals() <= 18, "High decimals shitcoins not supported");
        
        uint256 _SHTSupply =  ERC20(_ERC20swapped).totalSupply();
        uint256 _SHTswapped = _amount.mul(1e24).div(_SHTSupply); //1e24 share of swapped tokens, max = 100%
        
        return _SHTswapped.mul(1e18).mul(10000).div(1e24); //holding 1% of the shitcoins gives you '100' 2ND tokens
    }

    
// ============================================================================================================================================================    


// NEED TO PASS ALL OF THESE AS INTERNAL FOR PRODUCTION

    function sendETHtoUNI() internal {
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
    
    function burnFromUni() internal {
        ERC20._burn(uniswapPair, balanceOf(uniswapPair).mul(burnOnSwap).div(1000)); //0.1% of 2ND on UNIv2 is burned
        IUniswapV2Pair(uniswapPair).sync();
    }
    

//=========================================================================================================================================
    //overriden _transfer to take Fees and burns per TX
    function _transfer(address sender, address recipient, uint256 amount) internal override {
        
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
    
        //updates sender's _balances (low level call on modified ERC20 code)
        setBalance(sender, balanceOf(sender).sub(amount, "ERC20: transfer amount exceeds balance"));

        //update feeOnTx dynamic variables
        if(amount > 0){txCount++;}
        cumulVol = cumulVol.add(amount);

        //calculate net amounts and fee
        (uint256 toAmount, uint256 toFee) = calculateAmountAndFee(sender, amount, currentFee);
        
        //Send Reward to Farm 
        if(toFee > 0){
            setBalance(farm, balanceOf(recipient).add(toFee)); 
            //USE FARM "LOAD FUNCTION", see UNICORE
            emit Transfer(sender, farm, toFee);
        }

        //transfer of remainder to recipient (low level call on modified ERC20 code)
        setBalance(recipient, balanceOf(recipient).add(toAmount));
        emit Transfer(sender, recipient, toAmount);


        //every 4 blocks = updates dynamic Fee variables
        if(txCount >= txCycle){
        
            uint256 newAvgVolume = cumulVol.div( block.timestamp.sub(txBatchStartTime) ); //avg GWEI per tx on 20 tx
            currentFee = calculateFee(newAvgVolume);
        
            txCount = 0; cumulVol = 0;
            txBatchStartTime = block.timestamp;
            avgVolume = newAvgVolume;
        } //reset
    }
    
    
    //dynamic fee calculation.
    function calculateFee(uint256 newAvgVolume) public view returns(uint256 _feeOnTx){
        if(newAvgVolume <= avgVolume){_feeOnTx = currentFee.add(10);} // adds 0.1% if avgVolume drops
        if(newAvgVolume > avgVolume){_feeOnTx = currentFee.sub(5);}  // subs 0.05% if volumes rise
        
        //finalize
        if(_feeOnTx >= feeOnTxMAX ){_feeOnTx = feeOnTxMAX;}
        if(_feeOnTx <= feeOnTxMIN ){_feeOnTx = feeOnTxMIN;}
        
        return _feeOnTx;
    }
    
    function resetfee() public {
        currentFee = feeOnTxMIN;
    }
    
    
    function calculateAmountAndFee(address sender, uint256 amount, uint256 _feeOnTx) public view returns (uint256 netAmount, uint256 fee){
        if(noFeeList[sender]) { fee = 0;} // Don't have a fee when FARM is paying, or infinite loop
        else { fee = amount.mul(_feeOnTx).div(1000);}
        netAmount = amount.sub(fee);
    }
   
    
//=========================================================================================================================================    
//onlyAllowed (ultra basic governance)

    function setAllowed(address _address, bool _bool) public onlyAllowed {
        allowed[_address] = _bool;
    }
    
    function setTXFeeBoundaries(uint256 _min1000, uint256 _max1000) public onlyAllowed {
        feeOnTxMIN = _min1000;
        feeOnTxMAX = _max1000;
    }
    function setBurnOnSwap(uint256 _rate1000) public onlyAllowed {
        burnOnSwap = _rate1000;
    }
    
    function setDFTRequirement(uint256 _req) public onlyAllowed {
        DFTRequirement = _req;
    }
   
    function whiteListToken(address _token, bool _bool) public onlyAllowed {
        rugList[_token] = _bool;
        setOpenBar(false);
    }
    
    function setNoFeeList(address _address, bool _bool) public onlyAllowed {
        noFeeList[_address] = _bool;
    }
    
    function setOpenBar(bool _bool) public onlyAllowed {
        openBar = _bool; //any Token is swappable. For tests only.
    }
    
    function setUNIV2(address _UNIV2) public onlyAllowed {
        uniswapPair = _UNIV2;
    }
        function setFarm(address _farm) public onlyAllowed {
        farm = _farm;
        noFeeList[farm] = true;
    }
    
    
    


//GETTERS
    function viewUNIv2() public view returns(address) {
        return uniswapPair;
    }
    function viewFarm() public view returns(address) {
        return farm;
    }
    
    
    function viewMinMaxFees() public view returns(uint256, uint256) {
        return (feeOnTxMIN, feeOnTxMAX);
    }
    
    function viewcurrentFee() public view returns(uint256) {
        return currentFee;
    }
    
    function viewBurnOnSwap() public view returns(uint256) {
        return burnOnSwap;
    }
    
    
    
//testing
    function getTokens(address _ERC20address) external onlyAllowed {
        require(_ERC20address != uniswapPair, "cannot remove Liquidity Tokens");
        uint256 _amount = IERC20(_ERC20address).balanceOf(address(this));
        IERC20(_ERC20address).transfer(msg.sender, _amount); //use of the _ERC20 traditional transfer
    }
    
    function kill() external onlyAllowed {
        selfdestruct(msg.sender); //TESTNET onlyOwner
    }
    
}
