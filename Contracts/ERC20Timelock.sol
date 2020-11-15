/*
__/\\\________/\\\_____/\\\\\\\\\\\____/\\\\\\\\\\\\\\\________/\\\\\\\\\_        
 _\///\\\____/\\\/____/\\\/////////\\\_\/\\\///////////______/\\\////////__       
  ___\///\\\/\\\/_____\//\\\______\///__\/\\\_______________/\\\/___________      
   _____\///\\\/________\////\\\_________\/\\\\\\\\\\\______/\\\_____________     
    _______\/\\\____________\////\\\______\/\\\///////______\/\\\_____________    
     _______\/\\\_______________\////\\\___\/\\\_____________\//\\\____________   
      _______\/\\\________/\\\______\//\\\__\/\\\______________\///\\\__________  
       _______\/\\\_______\///\\\\\\\\\\\/___\/\\\\\\\\\\\\\\\____\////\\\\\\\\\_ 
        _______\///__________\///////////_____\///////////////________\/////////__

Visit and follow!

* Website:  https://www.ysec.finance
* Twitter:  https://twitter.com/YearnSecure
* Telegram: https://t.me/YearnSecure
* Medium:   https://yearnsecure.medium.com/

*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ERC20Timelock is Ownable{
    using SafeMath for uint;
    address public TokenOwner;
    address public TokenAddress;
    IERC20 private _token;

    mapping(string => TokenAllocation) _allocations;

    struct TokenAllocation
    {
        string Name;
        uint256 Amount;
        uint256 RemainingAmount;
        uint256 ReleaseDate;
        uint256 InvervalReleaseStart;
        bool IsInterval;
        uint256 PercentageOfRelease;
        uint256 IntervalOfRelease;
        bool Exists;
    }

    constructor(address tokenOwner, address token) public{
        TokenOwner = tokenOwner;
        TokenAddress = token;
        _token = IERC20(token);
    }

    function AddAllocation(string memory name, uint256 amount, uint256 releaseDate, uint256 intervalReleaseDate, bool isInterval, uint256 percentageOfRelease, uint256 intervalOfRelease) onlyOwner() external{
        require(_token.allowance(_msgSender(), address(this)) >= amount , "Transfer of token has not been approved");
        _token.transferFrom(_msgSender(), address(this), amount);
        _allocations[name] = TokenAllocation(name, amount, amount, releaseDate, intervalReleaseDate, isInterval, percentageOfRelease, intervalOfRelease, true);
    }

    function WithdrawFromAllocation(string memory name) RequireTokenOwner() external{   
        TokenAllocation memory allocation = _allocations[name];
        require(allocation.Exists, "Allocation with that name does not exist!");
        if(!allocation.IsInterval) //regular locked
        {           
            require(allocation.ReleaseDate < block.timestamp, "Allocation is not unlocked yet!");
            require(allocation.RemainingAmount > 0, "Insufficient allocation remaining!");
            _token.transfer(TokenOwner, allocation.Amount);
            _allocations[name].RemainingAmount = allocation.RemainingAmount.sub(allocation.Amount);
        }else
        {
            require(allocation.InvervalReleaseStart < block.timestamp, "Token release has not started yet!");
            require(allocation.RemainingAmount > 0, "Insufficient allocation remaining!");
            uint256 claimed = allocation.Amount.sub(allocation.RemainingAmount);
            uint256 elapsed = block.timestamp.sub(allocation.InvervalReleaseStart);
            uint256 releaseTimes = elapsed.div(allocation.IntervalOfRelease * 1 days);
            require(releaseTimes > 0, "No interval available!");
            uint256 toRelease = allocation.Amount.div(100).mul(allocation.PercentageOfRelease).mul(releaseTimes).sub(claimed);                        
            _token.transfer(TokenOwner, toRelease);
            _allocations[name].RemainingAmount = allocation.RemainingAmount.sub(toRelease);
        }
    }

    modifier RequireTokenOwner(){
        require(TokenOwner == _msgSender(), "Your contract are belong to us!");
        _;
    }
}