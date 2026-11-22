
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



-- TASK 3 - ALTER: the business changes

-- 3.1
ALTER TABLE Membership.Member
    ADD CONSTRAINT FK_Member_City FOREIGN KEY (CityId)
        REFERENCES Membership.City (Id);

ALTER TABLE Membership.Member
    ADD CONSTRAINT FK_Member_Member FOREIGN KEY (InvitedBy)
        REFERENCES Membership.Member (Id);

ALTER TABLE Membership.Wallet
    ADD CONSTRAINT FK_Wallet_Member FOREIGN KEY (MemberId)
        REFERENCES Membership.Member (Id);

ALTER TABLE Logistics.Warehouse
    ADD CONSTRAINT FK_Warehouse_City FOREIGN KEY (CityId)
        REFERENCES Membership.City (Id);

ALTER TABLE Logistics.Warehouse
    ADD CONSTRAINT FK_Warehouse_Employee FOREIGN KEY (ManagerId)
        REFERENCES Logistics.Employee (Id);

ALTER TABLE Logistics.Employee
    ADD CONSTRAINT FK_Employee_Member FOREIGN KEY (MemberId)
        REFERENCES Membership.Member (Id);

ALTER TABLE Logistics.Employee
    ADD CONSTRAINT FK_Employee_Warehouse FOREIGN KEY (WarehouseId)
        REFERENCES Logistics.Warehouse (Id);

ALTER TABLE Catalog.Category
    ADD CONSTRAINT FK_Category_Category FOREIGN KEY (ParentCode)
        REFERENCES Catalog.Category (CategoryCode);

ALTER TABLE Catalog.Item
    ADD CONSTRAINT FK_Item_Member_Seller FOREIGN KEY (SellerId)
        REFERENCES Membership.Member (Id);

ALTER TABLE Catalog.Item
    ADD CONSTRAINT FK_Item_Member_Inspector FOREIGN KEY (InspectorId)
        REFERENCES Membership.Member (Id);

ALTER TABLE Catalog.Item
    ADD CONSTRAINT FK_Item_Category FOREIGN KEY (CategoryCode)
        REFERENCES Catalog.Category (CategoryCode);

ALTER TABLE Catalog.Item
    ADD CONSTRAINT FK_Item_Warehouse FOREIGN KEY (WarehouseId)
        REFERENCES Logistics.Warehouse (Id);

ALTER TABLE Catalog.ItemPhoto
    ADD CONSTRAINT FK_ItemPhoto_Item FOREIGN KEY (ItemId)
        REFERENCES Catalog.Item (Id)
        ON DELETE CASCADE;

ALTER TABLE Sales.Bid
    ADD CONSTRAINT FK_Bid_Auction FOREIGN KEY (AuctionId)
        REFERENCES Sales.Auction (Id);

ALTER TABLE Sales.Bid
    ADD CONSTRAINT FK_Bid_Member FOREIGN KEY (MemberId)
        REFERENCES Membership.Member (Id);

ALTER TABLE Sales.AuctionFollow
    ADD CONSTRAINT FK_AuctionFollow_Member FOREIGN KEY (MemberId)
        REFERENCES Membership.Member (Id);

ALTER TABLE Sales.AuctionFollow
    ADD CONSTRAINT FK_AuctionFollow_Auction FOREIGN KEY (AuctionId)
        REFERENCES Sales.Auction (Id);
GO

-- 3.2
ALTER TABLE Membership.Member
    ADD AppLanguage CHAR(2) NOT NULL
        CONSTRAINT DF_Member_AppLanguage DEFAULT 'ar'
        CONSTRAINT CK_Member_AppLanguage CHECK (AppLanguage IN ('ar', 'en'));
GO

-- 3.3
ALTER TABLE Catalog.Item
    ADD IsFeatured BIT NOT NULL
        CONSTRAINT DF_Item_IsFeatured DEFAULT 0;
GO

-- 3.4
EXEC sp_rename 'Sales.Bid.IpAddress', 'DeviceIp', 'COLUMN';

ALTER TABLE Logistics.Warehouse
    DROP CONSTRAINT CK_Warehouse_Capacity;

EXEC sp_rename 'Logistics.Warehouse.Capacity', 'MaxItems', 'COLUMN';

ALTER TABLE Logistics.Warehouse
    ADD CONSTRAINT CK_Warehouse_MaxItems CHECK (MaxItems > 0);
GO


-- 3.5
ALTER TABLE Membership.Member
    ALTER COLUMN FullName NVARCHAR(150) NOT NULL;

-- 3.6
ALTER TABLE Logistics.Warehouse
    DROP CONSTRAINT CK_Warehouse_MaxItems;

ALTER TABLE Logistics.Warehouse
    ALTER COLUMN MaxItems SMALLINT NOT NULL;

ALTER TABLE Logistics.Warehouse
    ADD CONSTRAINT CK_Warehouse_MaxItems CHECK (MaxItems > 0 AND MaxItems <= 30000);

GO

-- 3.7
ALTER TABLE Catalog.Category
    DROP CONSTRAINT CK_Category_CommissionPercent;

ALTER TABLE Catalog.Category
    ADD CONSTRAINT CK_Category_CommissionPercent CHECK (CommissionPercent BETWEEN 0 AND 25);
GO

-- 3.8
ALTER TABLE Sales.Auction
    DROP CONSTRAINT CK_Auction_Status, DF_Auction_Status;

ALTER TABLE Sales.Auction
    ADD CONSTRAINT CK_Auction_Status CHECK (Status IN ('PendingReview', 'Draft', 'Live', 'Ended', 'Cancelled')),
        CONSTRAINT DF_Auction_Status DEFAULT 'PendingReview' FOR Status;
GO

-- 3.9
ALTER TABLE Sales.Auction
    ADD BuyNowPrice DECIMAL(12,2) NULL;
GO

-- WITH CHECK: the new column is NULL in every existing row, and a CHECK on NULL
-- evaluates to UNKNOWN (which passes), so validating the old rows is safe and
-- cheap. WITH CHECK also keeps the constraint "trusted" so the optimizer can use it. 
-- WITH NOCHECK would skip the old rows and leave the constraint untrusted;
-- it is only needed when existing rows already break the rule and cannot be fixed.

ALTER TABLE Sales.Auction
    WITH CHECK
    ADD CONSTRAINT CK_Auction_BuyNowPrice CHECK (BuyNowPrice > StartingPrice);
GO

-- 3.10
ALTER TABLE Membership.Member
    ADD CONSTRAINT UQ_Member_Mobile UNIQUE (Mobile);
GO

-- 3.11
ALTER TABLE Membership.Member
    ADD VerifiedAt DATETIME2(3) NULL;

ALTER TABLE Membership.Member
    DROP CONSTRAINT DF_Member_IsVerified;

ALTER TABLE Membership.Member
    DROP COLUMN IsVerified;

GO
-- 3.12
CREATE SCHEMA Marketing;
Go
ALTER SCHEMA Marketing TRANSFER Sales.AuctionFollow;
GO





