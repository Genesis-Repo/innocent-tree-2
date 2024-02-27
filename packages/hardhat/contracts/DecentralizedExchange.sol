// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract DecentralizedExchange {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    struct TokenPair {
        address token1;
        address token2;
    }

    address[] public registeredTokens;
    TokenPair[] public tokenPairs;
    mapping(address => mapping(address => uint256)) public balance;

    event TokenRegistered(address indexed tokenAddress);
    event TokenPairCreated(address indexed token1, address indexed token2);
    event TokenSwap(address indexed token1, address indexed token2, address indexed sender, uint256 amount);
    event LimitOrderCreated(address tokenBuy, address tokenSell, address sender, uint256 amount, uint256 exchangeRate);

    function registerToken(address _tokenAddress) external {
        require(isTokenRegistered(_tokenAddress) == false, "Token is already registered");
        registeredTokens.push(_tokenAddress);
        emit TokenRegistered(_tokenAddress);
    }

    function isTokenRegistered(address _tokenAddress) internal view returns (bool) {
        for (uint256 i = 0; i < registeredTokens.length; i++) {
            if (registeredTokens[i] == _tokenAddress) {
                return true;
            }
        }
        return false;
    }

    function createTokenPair(address _token1, address _token2) external {
        require(isTokenRegistered(_token1) == true, "Token1 is not registered");
        require(isTokenRegistered(_token2) == true, "Token2 is not registered");
        TokenPair memory newTokenPair = TokenPair(_token1, _token2);
        tokenPairs.push(newTokenPair);
        emit TokenPairCreated(_token1, _token2);
    }

    function swapToken(address _token1, address _token2, uint256 _amount) external {
        require(isTokenPairCreated(_token1, _token2) == true, "Token pair does not exist");
        require(balance[msg.sender][_token1] >= _amount, "Insufficient balance");
        uint256 token2Amount = _amount;
        IERC20(_token1).safeTransferFrom(msg.sender, address(this), _amount);
        IERC20(_token2).safeTransfer(msg.sender, token2Amount);
        balance[msg.sender][_token1] = balance[msg.sender][_token1].sub(_amount);
        emit TokenSwap(_token1, _token2, msg.sender, _amount);
    }

    function isTokenPairCreated(address _token1, address _token2) internal view returns (bool) {
        for (uint256 i = 0; i < tokenPairs.length; i++) {
            TokenPair memory pair = tokenPairs[i];
            if ((pair.token1 == _token1 && pair.token2 == _token2) || (pair.token1 == _token2 && pair.token2 == _token1)) {
                return true;
            }
        }
        return false;
    }
    
    // New function to create a limit order
    function createLimitOrder(address _tokenBuy, address _tokenSell, uint256 _amount, uint256 _exchangeRate) external {
        require(isTokenPairCreated(_tokenBuy, _tokenSell) == true, "Token pair does not exist");
        
        // Calculate the amount of _tokenBuy needed based on the exchange rate
        uint256 amountToBuy = _amount * _exchangeRate;
        
        // Transfer _amount of _tokenSell from the sender to the contract
        IERC20(_tokenSell).safeTransferFrom(msg.sender, address(this), _amount);
        
        // Emit an event for the created limit order
        emit LimitOrderCreated(_tokenBuy, _tokenSell, msg.sender, amountToBuy, _exchangeRate);
    }
}