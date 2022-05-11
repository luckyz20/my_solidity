// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

/*
    @desc 众筹智能合约 合约地址:0xe048d7Db102537272E31B8E9AB3474b476FEE729
    @url https://rinkeby.etherscan.io/address/0xe048d7Db102537272E31B8E9AB3474b476FEE729
    @creator zhao
    @date 2022
 */
contract Donate {

    address public owner; //合约拥有者

    uint public doneeCount; //筹资人数量
    mapping(uint => Donee) doneeMap; //筹资人字典

    //构造函数
    constructor() {
        owner = msg.sender; //设置合约拥有者
    }

    //销毁合约
    function destroy() public onlyOwner {
        selfdestruct(payable(owner));
    }

    //修饰器：验证拥有者权限
    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }

     //修饰器：验证筹资项目ID合法性
    modifier validDonee(uint doneeID){
        require(doneeID > 0 && doneeID <= doneeCount);
        _;
    }

    //筹资事件
    event DoneeEvent (
        address addr,
        uint goal,
        uint amount,
        uint donorCount,
        bool status
    );

    //1 设置筹资人和筹资金额
    function setDonee(address addr,uint goal) public onlyOwner {
        for (uint256 i = 0; i < doneeCount; i++) {
            Donee storage d = doneeMap[i+1];
            if(d.addr == addr){
                d.goal = goal;
                return;
            }
        }

        doneeCount++;
        Donee storage donee = doneeMap[doneeCount];
        donee.addr = addr;
        donee.goal = goal;
        donee.status = true;
    }

    //2 出资人捐赠投资
    function donate(uint doneeID) public payable validDonee(doneeID){
        Donee storage donee = doneeMap[doneeID];
        require(donee.status);

        if(!donee.donorMap[msg.sender].used){ //是否是新出资人
            donee.donorCount++;
        }
        
        donee.amount += msg.value; //出资人金额

        Donor storage donor = donee.donorMap[msg.sender];
        donor.addr = msg.sender;
        donor.amount = msg.value;
        donor.used = true;

        //达成捐赠目标触发筹资事件
        if(donee.amount >= donee.goal) {
            emit DoneeEvent(donee.addr, donee.goal, donee.amount, donee.donorCount, donee.status);
        }

    }

    //3 完成筹集目标后转账给筹资人
    function transfer(uint doneeID) public onlyOwner validDonee(doneeID) {
        Donee storage donee = doneeMap[doneeID];
        if(donee.amount >= donee.goal){
            //已完成，可以转账
            payable(donee.addr).transfer(donee.goal);
        }else{
            //余额不足
            revert();
        }
    }

    //4 将合约账户中的资金提取到拥有者账户
    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    //5 获取筹资人的信息
    function getDonee(uint doneeID) public view validDonee(doneeID) returns (address doneeAddr,uint doneeGoal, uint doneeAmount, bool doneeStatus){
        return (doneeMap[doneeID].addr,doneeMap[doneeID].goal, doneeMap[doneeID].amount, doneeMap[doneeID].status);
    }

    //6 设置项目状态是否有效
    function setStatus(uint doneeID, bool doneeStatus) public onlyOwner {
        Donee storage d = doneeMap[doneeID];
        d.status = doneeStatus;
    }
    
    //6 获取当前合约余额
    function getBalance() public view returns(uint){
        return address(this).balance;
    }
    
    // 转账，须有如下函数，否则异常
    fallback() external {

    }
    receive() payable external {

    }

}

/**
    筹资人
 */
struct Donee {
    address addr; //筹资人
    uint goal; //筹资目标金额
    uint amount; //已筹集金额
    uint donorCount; //捐赠人数
    bool status; //true 有效 false 无效
    mapping(address => Donor) donorMap; //捐赠人字典

}

/**
    出资人
 */
 struct Donor {
     address addr; //出资人地址
     uint amount; //出资人金额
     bool used; //是否被用
 }