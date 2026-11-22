
# NOTES.md

## 1. Schemas and why

I divided the 11 tables into 4 schemas. No table is in `dbo`.

| Schema | Tables | Why |
|---|---|---|
| **Membership** | `City`, `Member`, `Wallet` | Member information, their city, and money. |
| **Logistics** | `Warehouse`, `Employee` | Warehouses and their employees. |
| **Catalog** | `Category`, `Item`, `ItemPhoto` | Items for sale, their categories, and photos. |
| **Sales** | `Auction`, `Bid`, `AuctionFollow` | Auctions, bids, and followers. |

Foreign keys can connect tables in different schemas. For example, `Sales.Bid.MemberId` points to `Membership.Member`.


---

## 2. Relationship types in BidNile

| Type | Where | How I implemented it |
|---|---|---|
| **1:1** | Member–Wallet, Member–Employee, Warehouse–Manager | A `UNIQUE` FK prevents more than one match. |
| **1:N** | City–Member, City–Warehouse, Warehouse–Employee, Category–Item, Warehouse–Item, Member–Item, Item–Auction, Auction–Bid, Member–Bid | The FK is placed in the many-side table. Optional FKs can be `NULL`. |
| **M:N** | Member–Auction (followers) | `AuctionFollow` is a junction table with a composite PK `(MemberId, AuctionId)`. |
| **Recursive** | Member invitations, Category tree | The FK points to the same table. `InvitedBy` and `ParentCode` can be `NULL`. |
| **Circular** | Warehouse–Employee | Both tables have FKs to each other.|
| **Weak Entity** | `ItemPhoto` | Its composite PK is `(ItemId, Position)`. Deleting an item deletes its photos using `ON DELETE CASCADE`. A `CHECK` limits photos to 20 per item. |


### 3 — Why GUID / BIGINT, FLOAT / DECIMAL, DATETIMEOFFSET?

**GUID for members.** The mobile app creates the member ID before sending the request. GUIDs are unique and cannot be easily guessed. If no ID is sent, `DEFAULT NEWID()` creates one.

**BIGINT for bids.** Bids use `IDENTITY` to generate numbers automatically. `INT` is too small for the expected number of bids, but `BIGINT` can store much more.

**FLOAT for GPS, DECIMAL for money.** GPS values are approximate, so `FLOAT` is suitable. Money must be exact, so `DECIMAL(12,2)` avoids rounding errors. This is important for balance checks and comparing bid amounts.

**DATETIMEOFFSET for auctions.** Members may use different time zones. `DATETIMEOFFSET` stores the time and its offset, so SQL Server can compare times correctly. `DATETIME2` doesn't store the offset.

`PlacedAt` and `RegisteredAt` use `DATETIME2(3)` because the server records them using the same time zone, with millisecond precision.


### 4 — Why can't the circular relationship be created inside CREATE TABLE?

`Warehouse.ManagerId` points to `Employee`, and `Employee.WarehouseId` points to `Warehouse`. Each table needs the other to exist first, so neither can be created with its FK directly.

**The solution:** Create both tables first, then add the FKs using `ALTER TABLE ... ADD CONSTRAINT`.

### 6 — The errors in 3.6 and 3.11, and how you fixed them.

## 3.4 — Renaming `Warehouse.Capacity` to `MaxItems`

**What I ran**
```sql
EXEC sp_rename 'Logistics.Warehouse.Capacity', 'MaxItems', 'COLUMN';
```

**Error**
```text
Msg 15336, Level 16, State 1, Procedure sp_rename, Line 773
Object 'Logistics.Warehouse.Capacity' cannot be renamed because the object participates in enforced dependencies.
```

**Cause:** `CK_Warehouse_Capacity` uses this column.

**Fix**
```sql
ALTER TABLE Logistics.Warehouse DROP CONSTRAINT CK_Warehouse_Capacity;

EXEC sp_rename 'Logistics.Warehouse.Capacity', 'MaxItems', 'COLUMN';

ALTER TABLE Logistics.Warehouse
ADD CONSTRAINT CK_Warehouse_MaxItems CHECK (MaxItems > 0);
```

I created the CHECK again with a new name to match the column name.

---

## 3.6 — Changing `MaxItems` to SMALLINT

`SMALLINT` can store 30,000, but `TINYINT` cannot.

**What I ran**
```sql
ALTER TABLE Logistics.Warehouse ALTER COLUMN MaxItems SMALLINT NOT NULL;
```

**Error**
```text
Msg 5074, Level 16
The object 'CK_Warehouse_MaxItems' is dependent on column 'MaxItems'.
Msg 4922, Level 16
ALTER TABLE ALTER COLUMN MaxItems failed because one or more objects access this column.
```

**Cause:** The CHECK constraint uses `MaxItems`.

**Fix**
```sql
ALTER TABLE Logistics.Warehouse DROP CONSTRAINT CK_Warehouse_MaxItems;

ALTER TABLE Logistics.Warehouse
ALTER COLUMN MaxItems SMALLINT NOT NULL;

ALTER TABLE Logistics.Warehouse
ADD CONSTRAINT CK_Warehouse_MaxItems
CHECK (MaxItems > 0 AND MaxItems <= 30000);
```

I kept the old rule and added a maximum value of 30,000.

---

## 3.11 — Dropping `Member.IsVerified`

**What I ran**
```sql
ALTER TABLE Membership.Member DROP COLUMN IsVerified;
```

**Error**
```text
Msg 5074, Level 16
The object 'DF_Member_IsVerified' is dependent on column 'IsVerified'.
Msg 4922, Level 16
ALTER TABLE DROP COLUMN IsVerified failed because one or more objects access this column.
```

**Cause:** The column has a DEFAULT constraint named `DF_Member_IsVerified`.

**Fix**
```sql
ALTER TABLE Membership.Member DROP CONSTRAINT DF_Member_IsVerified;

ALTER TABLE Membership.Member DROP COLUMN IsVerified;
```

### 7- The hand trace from Task 5.

# Hand Trace — Product of Array Except Self

**Input:**
```text
nums = [1, 2, 3, 4]
```

## Prefix Accumulation

Prefix = Product of all elements before the current index.

| Index | nums[i] | Prefix |
|---|---:|---:|
| 0 | 1 | 1 |
| 1 | 2 | 1 |
| 2 | 3 | 2 |
| 3 | 4 | 6 |

**Prefix Array:**
```text
[1, 1, 2, 6]
```

## Suffix Accumulation

Suffix = Product of all elements after the current index.

| Index | nums[i] | Suffix |
|---|---:|---:|
| 0 | 1 | 24 |
| 1 | 2 | 12 |
| 2 | 3 | 4 |
| 3 | 4 | 1 |

**Suffix Array:**
```text
[24, 12, 4, 1]
```

## Final Calculation

Answer[i] = Prefix[i] * Suffix[i]

| Index | Prefix | Suffix | Answer |
|---|---:|---:|---:|
| 0 | 1 | 24 | 24 |
| 1 | 1 | 12 | 12 |
| 2 | 2 | 4 | 8 |
| 3 | 6 | 1 | 6 |

**Output:**
```text
[24, 12, 8, 6]
```
