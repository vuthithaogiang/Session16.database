use Northwind

-- PART 3: sử dụng 3 bảng Customers, Orders, Products 

-- 1: tạo một insert trigger có tên là checkCustomerOnInsert cho bảng Customer
-- nv: kiểm tra thao tác chèn dữ liệu, xe trường phone có phải là nul hay không ?
-- nếu null thì không cho phép chèn dữ liệu

select top 10  *  
from Customers

create trigger checkCustomerOnInsert 
on dbo.Customers
after insert
as
  begin
     declare @phonenumber nvarchar(24);
	 select @phonenumber = Phone from inserted;

	 if @phonenumber is null 
	    begin
		    print 'Khong duoc phep them gia tri null vao Phone';
			rollback transaction;
		end

  end


insert into Customers (CustomerID, CompanyName, Phone)  values ('A111', 'Comp', null)

insert into Customers (CustomerID, CompanyName, Phone) values ('A111', 'Comp','1234566')


--2: tạo một uodate trigger checkCustomerOnUpdate cho bảng Customer
-- nv: không choe phép thay đỏi những khách hàng có tên nước là France

create trigger checkCustomerOnUpdate
on Customers
after update
as
begin
   declare @country nvarchar(15)
   select @country = Country from inserted

   if @country like 'France'
      begin 
	    print 'Khong duoc phep thay doi thong tin Customer o France';
			rollback transaction;

	  end
end

update Customers 
set Phone = '111111'
where Country like 'France'

--3: chèn một cột mói có tê là Active vào bảng Customer và đặt giá trị mặc định cho nó là 1
-- tại trigger checkCustomerInsteadOfDelete nhằm chuyển giá trị cột active thành 0
-- thay vì tiến hàng xóa dữ liệu thực sự ra khỏi bảng khi thao tác xóa dữ liệu tiến hành

-- add column Active default value = 1 vao table Customers
alter table Customers
add Active bit
update Customers
set Active = 1 where Active is null

alter trigger checkCustomerInsteadOfDelete 
on Customers
for delete
as
begin 
   update
	  Customers
    set  Customers.Active = 0
	where Customers.CustomerID in (select deleted.CustomerID from deleted)
	print 'Delete complete: Active = 0 ';
	rollback transaction
end


delete from Customers
where CustomerID like 'A111'



select * from Customers

-- 4: thay dổi mức đọ ưu tiên của trigger checkCustomerCountryOnUpdate 
-- lên mức cao nhất

sp_settriggerorder @triggername='checkCustomerOnUpdate', 
@order='First' , @stmttype = 'Update';

--5: tạo một trigger có tên safety nhằm vô hiệu hóa các  thao tác: 
--	CREATE_TABLE, DROP_TABLE, ALTER_TABLE
create trigger safety
on database
for create_table,
     drop_table,
	 alter_table

as
begin
   set nocount on;
   print 'Do not allow create table, drop table and alter table';
   rollback transaction;
end

create table NewCustomer (id int not null)

--6: xóa tất cả các trigger vừa tạo

drop  trigger if exists safety

drop trigger if exists checkCustomerOnInsert

drop trigger if exists checkCustomerOnUpdate

drop trigger if exists checkCustomerInsteadOfDelete