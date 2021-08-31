// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";

contract ERC20_ReturnAToken is IERC20{
    //mapping to hold balances against EOA accounts
    mapping (address => uint256) private _balances;

    //mapping to hold approved allowance of token to certain address
    //       Owner               Spender    allowance
    mapping (address => mapping (address => uint256)) private _allowances;
    
    // mapping (address => mapping (uint256 => uint256)) private _tokensBought;
    

    //the amount of tokens in existence
    uint256 private _totalSupply;

    //owner
    address public owner;
    
    string public name;
    string public symbol;
    uint256 public decimals;
    uint256 public perTokenPrice;
    

    // events
    event Price(bool success,uint256 price);
    event TokensSold(address owner, address recipient, uint256 numberOfTokens);
    event AmountReceived(string);
    event returnToken(uint256 _numberOfWeiTokensToReturn, address tokenOwner, uint256 _amount);
    
    //modifier for owner transactions only
    modifier ownerOnly(){
        require(msg.sender == owner, "R-A-Token: Only token owner allowed");
        _;
    }

    constructor () {
        
        name = "ERC20_ReturnAToken";
        symbol = "R-A-Token";
        decimals = 18;  //1  - 1000 PKR 1 = 100 Paisa 2 decimal
        owner = msg.sender;
        perTokenPrice = 1e18/100;
        
        //1 million tokens to be generated
        _totalSupply = 1000000 * 10**decimals; //exponenctial farmola
        
        //transfer total supply to owner
        _balances[owner] = _totalSupply;
        
        //fire an event on transfer of tokens
        emit Transfer(address(this),owner,_totalSupply);
     }
       
    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     * Amount to be taken as wei i.e. 1 ether = 100000000000000000 (1e18).
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        address sender = msg.sender;
        require(sender != address(0), "R-A-Token: Address must be valid");
        require(recipient != address(0), "R-A-Token: Address must be valid");
        require(_balances[sender] > amount,"R-A-Token: transfer amount exceeds balance");

        //decrease the balance of token sender account
        _balances[sender] = _balances[sender] - amount;
        
        //increase the balance of token recipient account
        _balances[recipient] = _balances[recipient] + amount;

        emit Transfer(sender, recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address tokenOwner, address spender) public view virtual override returns (uint256) {
        return _allowances[tokenOwner][spender]; //return allowed amount
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address tokenOwner = msg.sender;
        require(tokenOwner != address(0), "R-A-Token: Address must be valid");
        require(spender != address(0), "R-A-Token: Address must be valid");
        
        _allowances[tokenOwner][spender] = amount;
        
        emit Approval(tokenOwner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address tokenOwner, address recipient, uint256 amount) public virtual override returns (bool) {
        address spender = msg.sender;
        uint256 _allowance = _allowances[tokenOwner][spender]; //how much allowed
        require(_allowance > amount, "R-A-Token: transfer amount exceeds allowance");
        
        //deducting allowance
        _allowance = _allowance - amount;
        
        //--- start transfer execution -- 
        
        //owner decrease balance
        _balances[tokenOwner] =_balances[tokenOwner] - amount; 
        
        //transfer token to recipient;
        _balances[recipient] = _balances[recipient] + amount;
        
        emit Transfer(tokenOwner, recipient, amount);
        //-- end transfer execution--
        
        //decrease the approval amount;
        _allowances[tokenOwner][spender] = _allowance;
        
        emit Approval(tokenOwner, spender, amount);
        
        return true;
    }
    
     /**
     * This function is to adjust the price of token
     *
     * Requirements:
     * - function only restricted to owner
     * - price must be valid
     */
    function adjustPrice(uint256 _price) public ownerOnly returns(bool){
        require(_price > 0, "R-A-Token: Token price must be valid");
        perTokenPrice = _price;
        emit Price(true, _price);
        return true;
    } 
    
    /**
     * This function lets buyer to buy tokens
     *
     * Requirements:
     * - function only restricted to EOA
     * - `recipient` must be valid
     * - numberOfTokens to be bought must be valid
     * - contract owner must have equal or greater tokens than the tokens to be bought
     */
    function buyToken() public payable returns(bool){
    
        address _recipient = msg.sender;
        
        require(_recipient != address(this), "B-A-Token: Buyer cannot be a contract");
        require(_recipient != address(0), "B-A-Token: Transfer to the zero address");
        require(_recipient != owner, "B-A-Token: Buyer can't be an owner");
        require(msg.value > 1 ether, "B-A-Token: Amount must be valid");
        
        
        uint256 _numberOfTokens = (msg.value*10**decimals)/perTokenPrice;
       
        require(_numberOfTokens > 0, "B-A-Token: Number of tokens must be valid");
        require(_balances[owner] >= _numberOfTokens, "B-A-Token: insufficient tokens");
        
        _balances[owner] = _balances[owner] - _numberOfTokens; 
        
        _balances[_recipient] = _balances[_recipient] + _numberOfTokens;
        
        
        emit TokensSold(owner, _recipient, _numberOfTokens);
        
        return true;
    }
      /**
     * This function will allow token owner to return tokens based on current pricing
     * 
     * Requirements:
     * - the caller must be Owner of token
     * - numberOfTokens must be valid
     */
    function tokenReturn(uint256 _numberOfWeiTokensToReturn) external returns(bool){
    
        require(msg.sender != address(0), "Address must be valid");
        require(_balances[msg.sender] > _numberOfWeiTokensToReturn, "tokenOwner has insufficient balance");
        
        //converts numberOfTokens to value(money) based on current tokenPrice
        uint256 _amount = _numberOfWeiTokensToReturn * perTokenPrice;
  
        
        require(_amount > 0, "Amount must be valid");
        require(_amount < address(this).balance, "Insufficient balance");
        
        //transfers tokens back to contractOwner 
        
        _balances[owner] = _balances[owner] + _numberOfWeiTokensToReturn * 10 ** decimals; 
        
        _balances[msg.sender] = _balances[msg.sender] - _numberOfWeiTokensToReturn * 10 ** decimals;
        
        //transfers money back to the tokenOwner
        payable(msg.sender).transfer(_amount);
        
        // Event fire
        emit returnToken(_numberOfWeiTokensToReturn, msg.sender, _amount);
        
        return true;
    }
    
    function addr() public view returns(uint){
        return address(this).balance;
    }

    
    /**
     * This is fallback function and sends tokens if anyone sends ether
     *
     * - if anyone sends 1 wei than 100 tokens will be transferred to him/her if 
     * tokenPrice is 0.01 ether i.e 10000000000000000 wei (subject to change with tokenPrice)
     */
     
    
    receive() external payable {
        buyToken();
        emit AmountReceived("Receive fallback");
    }
}
    
