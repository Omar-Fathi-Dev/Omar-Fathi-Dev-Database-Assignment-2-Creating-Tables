
-- Task 2 — CREATE
--============================================================

CREATE DATABASE BidNile;
GO

USE BidNile;
GO

CREATE SCHEMA Membership;
GO

CREATE SCHEMA Logistics;
GO

CREATE SCHEMA Catalog;
GO

CREATE SCHEMA Sales;
GO

-- MEMBERSHIP schema

CREATE TABLE Membership.City
(
    Id          INT IDENTITY(1,1) NOT NULL,
    Name        NVARCHAR(60)      NOT NULL,   
    CountryCode CHAR(2)           NOT NULL,   

    CONSTRAINT PK_City                  PRIMARY KEY (Id),
    CONSTRAINT UQ_City_Name_CountryCode UNIQUE (Name, CountryCode),
    CONSTRAINT CK_City_CountryCode      CHECK (CountryCode IN ('EG', 'SA', 'AE'))
);
GO


CREATE TABLE Membership.Member
(
    Id           UNIQUEIDENTIFIER NOT NULL
                 CONSTRAINT DF_Member_Id DEFAULT NEWID(),
    FullName     NVARCHAR(100)    NOT NULL,   
    Email        VARCHAR(254)     NOT NULL,   
    Mobile       VARCHAR(16)      NOT NULL,  
    NationalId   VARCHAR(20)      NOT NULL, 
    BirthDate    DATE             NOT NULL,
    IsVerified   BIT              NOT NULL
                 CONSTRAINT DF_Member_IsVerified DEFAULT 0,
    RegisteredAt DATETIME2(3)     NOT NULL
                 CONSTRAINT DF_Member_RegisteredAt DEFAULT SYSDATETIME(),
    CityId       INT              NOT NULL,   
    InvitedBy    UNIQUEIDENTIFIER NULL,      

    CONSTRAINT PK_Member            PRIMARY KEY (Id),
    CONSTRAINT UQ_Member_Email      UNIQUE (Email),
    CONSTRAINT UQ_Member_NationalId UNIQUE (NationalId),
    CONSTRAINT CK_Member_BirthDate  CHECK (BirthDate <= DATEADD(YEAR, -18, CAST(SYSDATETIME() AS DATE)))
);
GO

CREATE TABLE Membership.Wallet
(
    Id         INT IDENTITY(1,1) NOT NULL,
    MemberId   UNIQUEIDENTIFIER  NOT NULL,    
    Balance    DECIMAL(12,2)     NOT NULL
               CONSTRAINT DF_Wallet_Balance DEFAULT 0,
    HeldAmount DECIMAL(12,2)     NOT NULL
               CONSTRAINT DF_Wallet_HeldAmount DEFAULT 0,
    Currency   CHAR(3)           NOT NULL
               CONSTRAINT DF_Wallet_Currency DEFAULT 'EGP',
    UpdatedAt  DATETIME2(3)      NOT NULL
               CONSTRAINT DF_Wallet_UpdatedAt DEFAULT SYSDATETIME(),

    CONSTRAINT PK_Wallet            PRIMARY KEY (Id),
    CONSTRAINT UQ_Wallet_MemberId   UNIQUE (MemberId),
    CONSTRAINT CK_Wallet_Balance    CHECK (Balance >= 0),
    CONSTRAINT CK_Wallet_HeldAmount CHECK (HeldAmount >= 0 AND HeldAmount <= Balance)
);
GO

-- LOGISTICS schema

CREATE TABLE Logistics.Warehouse
(
    Id           INT IDENTITY(1,1) NOT NULL,
    Name         NVARCHAR(80)      NOT NULL,  
    Capacity     INT               NOT NULL,   
    Latitude     FLOAT             NOT NULL,
    Longitude    FLOAT             NOT NULL,
    CityId       INT               NOT NULL,   
    ManagerId    INT               NULL,       
    ManagedSince DATE              NULL,

    CONSTRAINT PK_Warehouse           PRIMARY KEY (Id),
    CONSTRAINT UQ_Warehouse_Name      UNIQUE (Name),
    CONSTRAINT CK_Warehouse_Capacity  CHECK (Capacity > 0),
    CONSTRAINT CK_Warehouse_Latitude  CHECK (Latitude  BETWEEN -90  AND 90),
    CONSTRAINT CK_Warehouse_Longitude CHECK (Longitude BETWEEN -180 AND 180)
);
GO

CREATE UNIQUE INDEX UQ_Warehouse_ManagerId
    ON Logistics.Warehouse (ManagerId)
    WHERE ManagerId IS NOT NULL;
GO

CREATE TABLE Logistics.Employee
(
    Id          INT IDENTITY(1,1) NOT NULL,
    MemberId    UNIQUEIDENTIFIER  NOT NULL,    
    WarehouseId INT               NOT NULL,   

    CONSTRAINT PK_Employee          PRIMARY KEY (Id),
    CONSTRAINT UQ_Employee_MemberId UNIQUE (MemberId)
);
GO

-- CATALOG schema


CREATE TABLE Catalog.Category
(
    CategoryCode      INT           NOT NULL,   
    NameEn            VARCHAR(50)   NOT NULL,   
    NameAr            NVARCHAR(50)  NULL,
    CommissionPercent DECIMAL(4,2)  NOT NULL,   
    ParentCode        INT           NULL,       

    CONSTRAINT PK_Category                  PRIMARY KEY (CategoryCode),
    CONSTRAINT UQ_Category_NameEn           UNIQUE (NameEn),
    CONSTRAINT CK_Category_CommissionPercent CHECK (CommissionPercent BETWEEN 0 AND 30)
);
GO

CREATE TABLE Catalog.Item
(
    Id             INT IDENTITY(1,1) NOT NULL,
    Title          NVARCHAR(150)     NOT NULL,
    Description    NVARCHAR(MAX)     NULL,      
    ConditionScore TINYINT           NOT NULL,   
    Specifications JSON              NOT NULL,   
    ListedAt       DATETIME2(3)      NOT NULL
                   CONSTRAINT DF_Item_ListedAt DEFAULT SYSDATETIME(),
    SellerId       UNIQUEIDENTIFIER  NOT NULL,   
    InspectorId    UNIQUEIDENTIFIER  NULL,       
    CategoryCode   INT               NOT NULL,   
    WarehouseId    INT               NULL,       

    CONSTRAINT PK_Item                      PRIMARY KEY (Id),
    CONSTRAINT CK_Item_ConditionScore       CHECK (ConditionScore BETWEEN 1 AND 10),
    CONSTRAINT CK_Item_SellerId_InspectorId CHECK (SellerId <> InspectorId)
);
GO


CREATE TABLE Catalog.ItemPhoto
(
    ItemId   INT           NOT NULL,   
    Position TINYINT       NOT NULL,   
    Url      VARCHAR(500)  NOT NULL,   
    IsMain   BIT           NOT NULL
             CONSTRAINT DF_ItemPhoto_IsMain DEFAULT 0,

    CONSTRAINT PK_ItemPhoto          PRIMARY KEY (ItemId, Position),
    CONSTRAINT CK_ItemPhoto_Position CHECK (Position BETWEEN 1 AND 20)
);
GO


-- SALES schema


CREATE TABLE Sales.Auction
(
    Id            INT IDENTITY(1,1) NOT NULL,
    ItemId        INT               NOT NULL,   
    StartingPrice DECIMAL(12,2)     NOT NULL,
    ReservePrice  DECIMAL(12,2)     NULL,       
    BidIncrement  DECIMAL(12,2)     NOT NULL
                  CONSTRAINT DF_Auction_BidIncrement DEFAULT 50.00,
    StartAt       DATETIMEOFFSET    NOT NULL,
    EndAt         DATETIMEOFFSET    NOT NULL,
    Status        VARCHAR(20)       NOT NULL
                  CONSTRAINT DF_Auction_Status DEFAULT 'Draft',

    CONSTRAINT PK_Auction              PRIMARY KEY (Id),
    CONSTRAINT CK_Auction_StartingPrice CHECK (StartingPrice > 0),
    CONSTRAINT CK_Auction_ReservePrice  CHECK (ReservePrice >= StartingPrice),
    CONSTRAINT CK_Auction_EndAt         CHECK (EndAt > StartAt),
    CONSTRAINT CK_Auction_Status        CHECK (Status IN ('Draft', 'Live', 'Ended', 'Cancelled'))
);
GO

CREATE TABLE Sales.Bid
(
    Id        BIGINT IDENTITY(1,1) NOT NULL,
    AuctionId INT                  NOT NULL,   
    MemberId  UNIQUEIDENTIFIER     NOT NULL,   
    Amount    DECIMAL(12,2)        NOT NULL,
    PlacedAt  DATETIME2(3)         NOT NULL
              CONSTRAINT DF_Bid_PlacedAt DEFAULT SYSDATETIME(),
    IpAddress VARCHAR(45)          NOT NULL,   

    CONSTRAINT PK_Bid                   PRIMARY KEY (Id),
    CONSTRAINT UQ_Bid_AuctionId_Amount  UNIQUE (AuctionId, Amount),
    CONSTRAINT CK_Bid_Amount            CHECK (Amount > 0)
);
GO

CREATE TABLE Sales.AuctionFollow
(
    MemberId   UNIQUEIDENTIFIER NOT NULL,   
    AuctionId  INT              NOT NULL,   
    FollowedAt DATETIME2(3)     NOT NULL
               CONSTRAINT DF_AuctionFollow_FollowedAt DEFAULT SYSDATETIME(),

    CONSTRAINT PK_AuctionFollow PRIMARY KEY (MemberId, AuctionId)
);
GO







