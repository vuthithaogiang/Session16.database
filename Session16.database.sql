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
drop trigger safety on database
  
drop trigger if exists checkCustomerOnInsert

drop trigger if exists checkCustomerOnUpdate

drop trigger if exists checkCustomerInsteadOfDelete


-- PART IV: 

create table Class (
   class_code varchar(10) primary key,
   head_teacher varchar(30) not null,
   room varchar(30) not null,
   time_slot char not null,
   close_date date 
)

create table Student ( 
 roll_no varchar(10) primary key,
 class_code varchar(10) foreign key references Class(class_code),
 full_name varchar(30) not null,
 male bit,
 birth_date date,
 address varchar(30),
 provice char(2),
 email varchar(30)
)

create table Subject(
  subject_code varchar(10) primary key,
  subject_name varchar(40) not null,
  w_mark bit,
  p_mark bit,
  wtest_per int,
  ptest_per int
)

create table Mark ( 
 roll_no varchar(10) foreign key references Student(roll_no),
 subject_code varchar(10) foreign key references Subject(subject_code),
 w_mark float,
 p_mark float,
 mark float,
 constraint Pk primary key (roll_no,subject_code) 
)

--1: tạo trigger cho thao tác insert của table Subject nhằm đảm bảo không có 
-- 2 subject cùng tên

alter trigger checkSubjectName
on Subject
for insert 
as
begin 
  if exists (select * from Subject as sb
  inner join inserted as  i on
     i.subject_name = sb.subject_name and i.subject_code <> sb.subject_code)

	begin
	  print 'Can not insert the same name of Subject!';
	  rollback transaction;
	end	 
end


    

insert into Subject (subject_code, subject_name) values ( 'SB114', 'C')
insert into Subject (subject_code, subject_name) values ( 'SB123', 'HTML, CSS')

select  * from Subject

--2: tạo một trigger cho bảng Student nhằm dảm bảo giá trị của cột Province phải 
-- bao gồm 2 kí tự

alter trigger checkStudentProvince
on Student
for insert
as
begin
   declare @provice char(2) 
   select @provice =  inserted.provice
   from inserted
   if len(@provice) not in (2)
   begin
     print 'the Provice must be 2 characters!';
	 rollback transaction;
   end
end

insert into Student (roll_no, full_name, provice) 
values ('ST112', 'nguyen van a', 'H');

--3: trigger cho thao tác insert Class nhằm đản bảo kí tự cuối cùng của timeSlot
-- phải bao gồm một trong các kí tự G, I, M, L


create trigger checkClassTimeSlot
on Class
for insert
as
begin
  declare @timeslot char

  select @timeslot = inserted.time_slot
  from inserted

  if (@timeslot not in ('g', 'i', 'l', 'm', 'G', 'I', 'L', 'M'))
  begin
  print 'Time slot in Class must be : G, I, L or M';
  rollback transaction;
  end
end


insert into Class (class_code, head_teacher, room, time_slot)
values ('C100', 'Teacer A', 'B10', 'G')

--4: trigger cho Subject đảm bảo khi xóa một Subject phải xóa hêt 
-- tat ca các Mark liên quan den subject do


delete from 
  Subject
where 
  subject_code not in (
     select min(s.subject_code) minId
	 from Subject as s
	 group by 
	    s.subject_name
  ) -- xoa ban ghi trung tao truoc do

select * from Subject
select * from Student 
select * from Mark

insert into Mark (roll_no, subject_code) values ('ST111', 'SB111' )
insert into Mark (roll_no, subject_code) values ('ST111', 'SB114' )


alter trigger checkSubjectOnDelete
on Subject 
for delete
as 
begin
    declare @subjectCode varchar(10)
    select   @subjectCode =  deleted.subject_code from 
          deleted 
    if( @subjectCode in (select Mark.subject_code from Mark))
	begin
	   print 'Remove info Subject in Mark first!';
	   rollback transaction;
	end
	else
	begin
	print 'Remove successfully!'
	end

end

alter table Mark 
   drop  constraint [FK__Mark__roll_no__151B244E]

alter table Mark
  drop constraint [FK__Mark__subject_co__160F4887]
alter table Mark
  add constraint  Fk_roll_no foreign key (roll_no) references Student (roll_no)

insert into Mark (roll_no, subject_code) values ('ST111', 'SB000')
insert into Mark (roll_no, subject_code) values ('ST111', 'SB2')
insert into Subject (subject_code, subject_name) values ('SB000', 'sad')
insert into Subject (subject_code, subject_name) values ('SB1', 'aaa')
insert into Subject (subject_code, subject_name) values ('SB2', 'bbb')
insert into Subject (subject_code, subject_name) values ('SB8', 'ccc')

delete Subject where subject_code = 'SB1'

delete Mark where subject_code = 'SB1'

select * from Subject
select * from Mark

select * from 
   Subject 
where subject_code in ( select Mark.subject_code from Mark)



--5: trigger cho Class để dảm bảo khi xóa một Class thì phải xóa kết tất cả Student
-- trong Class đó, và trước đó phải xóa hết Mark của student thuộc class dang xóa
create trigger checkClassRemoveStudent
on Class
for delete
as
begin
  declare @classCode varchar(10)
  select @classCode = deleted.class_code from deleted

  if ( @classCode in (select Student.class_code from Student))
  begin
     print 'Do not remove Class already have student!';
	 rollback transaction;
  end
end

create trigger checkStudentRemoveMark
on Student
for delete
as
begin
  declare @StudentRoll varchar(10)
  select @StudentRoll = deleted.roll_no from deleted

  if(@StudentRoll in ( select Mark.roll_no from Mark))
  begin
     print 'Do not remove Student already mark';
	 rollback transaction;
  end
end


select * from Student
select * from Mark
select * from Class

alter table Mark
  drop constraint [Fk_roll_no]

delete Student where roll_no = 'ST111'

--6: Trigger ngăn chặn việc xóa môn học đã có hơn 5 sinh viên dự thi
-- mon học có it hơn 5 sv có thể xóa: cần xóa trước mark của môn học này trước khi xóa nó

create trigger checkRemoveSubjectLeast5Student
on Subject
for delete
as 
begin
  declare @subjectCode varchar(10)
  select @subjectCode  = deleted.subject_code from deleted

  if ( select count(*) from Mark where Mark.subject_code = @subjectCode ) >= 5 
  begin
  print 'Dont remove subject already >=5 student!';
  rollback transaction;

  end
end