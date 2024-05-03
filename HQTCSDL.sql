CREATE DATABASE HQTCSDL
-- Tạo bảng Môn Học
CREATE TABLE Môn_Học (
    id INT PRIMARY KEY,
    name NVARCHAR(100),
    số_tín_chỉ INT
);




-- Tạo bảng Sinh viên
CREATE TABLE Sv (
    masv VARCHAR(13) PRIMARY KEY,
    name NVARCHAR(100),
    giới_tính BIT,
    lopsv VARCHAR(10)
);


-- Tạo bảng Giáo viên
CREATE TABLE Gv (
    id INT PRIMARY KEY,
    name NVARCHAR(100),
    bộ_môn NVARCHAR(100)
);


-- Tạo bảng Lớp Học Phần
CREATE TABLE LopHP (
    id INT PRIMARY KEY,
    idMon INT,
    họcky INT,
    name NVARCHAR(100),
    idGv INT,
    FOREIGN KEY (idMon) REFERENCES Môn_Học(id),
    FOREIGN KEY (idGv) REFERENCES Gv(id)
);


-- Tạo bảng Đăng ký môn học
CREATE TABLE Dkmh (
    id INT PRIMARY KEY,
    idLopHP INT,
    masv VARCHAR(13),
    điểmKt FLOAT,
    điểmThi FLOAT,
    FOREIGN KEY (idLopHP) REFERENCES LopHP(id),
    FOREIGN KEY (masv) REFERENCES Sv(masv)
);
-- Bài tập 1: Tính điểm trung bình 1 học kỳ của 1 sinh viên
CREATE FUNCTION fn_diem (@hk INT, @masv VARCHAR(13))
RETURNS FLOAT
AS
BEGIN
    DECLARE @diem FLOAT
    
    SELECT @diem = ((điểmKt * 0.4) + (điểmThi * 0.6))
    FROM Dkmh d
    JOIN LopHP l ON d.idLopHP = l.id
    WHERE l.họcky = @hk AND d.masv = @masv

    RETURN @diem
END;
GO


-- Bài tập 2: Tính điểm trung bình học kỳ của 1 lớp sinh viên
CREATE FUNCTION fn_diem_lopsv (@hk INT, @lopsv VARCHAR(10))
RETURNS @kq TABLE (masv VARCHAR(13), name NVARCHAR(50), giới_tính BIT, điểm_tb FLOAT)
AS
BEGIN
    INSERT INTO @kq (masv, name, giới_tính, điểm_tb)
    SELECT sv.masv, sv.name, sv.giới_tính, AVG((dkmh.điểmKt * 0.4) + (dkmh.điểmThi * 0.6)) AS điểm_tb
    FROM Sv sv
    JOIN Dkmh dkmh ON sv.masv = dkmh.masv
    JOIN LopHP lop ON dkmh.idLopHP = lop.id
    WHERE lop.họcky = @hk AND sv.lopsv = @lopsv
    GROUP BY sv.masv, sv.name, sv.giới_tính

    RETURN
END;
GO

-- Bài tập 3: Lấy danh mục môn học, lớp học phần và giáo viên dưới dạng JSON
CREATE PROCEDURE sp_danh_muc(@hk INT)
AS
BEGIN
    SELECT (
        SELECT id, name, số_tín_chỉ
        FROM Môn_Học
        FOR JSON PATH
    ) AS Mon_Hoc,
    (
        SELECT id, idMon, họcky, name, idGv
        FROM LopHP
        WHERE họcky = @hk
        FOR JSON PATH
    ) AS lophp,
    (
        SELECT id, name, bộ_môn
        FROM Gv
        WHERE id IN (SELECT DISTINCT idGv FROM LopHP WHERE họcky = @hk)
        FOR JSON PATH
    ) AS Giáo_viên
    FOR JSON PATH;
END;
GO

-- Bài tập 4: Lấy danh sách đăng ký lớp học phần dưới dạng JSON
CREATE PROCEDURE sp_danh_sach_dk @idLopHP INT
AS
BEGIN
    SELECT *
    FROM Dkmh
    WHERE idLopHP = @idLopHP
    FOR JSON PATH;
END;
GO

-- Bài tập 5: Lấy danh sách môn học của một giáo viên trong một học kỳ dưới dạng JSON
CREATE PROCEDURE sp_monhoc_giaovien @idgv INT, @hk INT
AS
BEGIN
SELECT DISTINCT mh.id, mh.name, mh.số_tín_chỉ
    FROM Môn_Học mh
    JOIN LopHP l ON mh.id = l.idMon
    WHERE l.idGv = @idgv AND l.họcky = @hk
    FOR JSON PATH;
END;
-- Nhập dữ liệu cho bảng môn học
INSERT INTO Môn_Học 
VALUES
(01, 'Toán', 6),
(02, 'Vật lý', 4),
(03, 'Hóa học', 3);


-- Nhập dữ liệu cho bảng Sinh viên
INSERT INTO Sv 
VALUES
('SV01', 'Hoàng', 1, 'K5'),
('SV02', 'Đức', 1, 'K5'),
('SV03', 'Long', 1, 'D5'),
('SV04', 'Hoàng', 1, 'D5'),
('SV05', 'Ngọc', 0, 'C1'),
('SV06', 'Thảo', 0, 'C2');

-- Nhập dữ liệu cho bảng Giáo viên
INSERT INTO Gv (id, name, bộ_môn) VALUES
(01, 'Nguyễn Ngọc Hậu', 'Toán'),
(02, 'Đinh Văn Mạnh', 'Vật lý'),
(03, 'Lâm Thu Hằng', 'Hóa học');

-- Nhập dữ liệu cho bảng Lớp Học Phần
INSERT INTO LopHP (id, idMon, họcky, name, idGv) VALUES
(5701, 01, 1, 'Đại số tuyến tính', 01),
(5602, 02, 1, 'Vật lý Đại cương', 02),
(5503, 03, 1, 'Hóa học Đại cương', 03);

-- Nhập dữ liệu cho bảng Đăng ký môn học
INSERT INTO Dkmh (id, idLopHP, masv, điểmKt, điểmThi) VALUES
(1, 5701, 'SV01', 4.0, 8.0),
(2, 5701, 'SV02', 6.0, 7.0),
(3, 5602, 'SV03', 7.5, 6.5),
(4, 5602, 'SV04', 8.0, 5.5),
(5, 5503, 'SV05', 9.0, 4.0),
(6, 5503, 'SV06', 5.5, 7.5);
-- Bài tập 1: Tính điểm trung bình 1 học kỳ của 1 sinh viên
DECLARE @diem_sv1 FLOAT
EXEC @diem_sv1 = fn_diem 1, 'SV01'
PRINT 'Điem trung binh cua sinh viên Hoàng trong hoc ky 1 la: ' + CAST(@diem_sv1 AS VARCHAR(10));


-- Bài tập 2: Tính điểm trung bình học kỳ của 1 lớp sinh viên
SELECT * FROM fn_diem_lopsv(1, 'K5');

-- Bài tập 3: Lấy danh mục môn học, lớp học phần và giáo viên dưới dạng JSON
EXEC sp_danh_muc 01;

-- Bài tập 4: Lấy danh sách đăng ký lớp học phần dưới dạng JSON
EXEC sp_danh_sach_dk 5602;

-- Bài tập 5: Lấy danh sách môn học của một giáo viên trong một học kỳ dưới dạng JSON
EXEC sp_monhoc_giaovien 1, 1;