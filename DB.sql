-- 1. 建立教練表 (Instructors)
CREATE TABLE coach (
    id_number VARCHAR(10) PRIMARY KEY,
    name VARCHAR(50) NOT NULL COMMENT '姓名',
    gender ENUM('男', '女') NOT NULL COMMENT '性別',
    birth_date DATE NOT NULL COMMENT '出生年月日',
    phone VARCHAR(20) NOT NULL COMMENT '聯絡電話',
    address VARCHAR(255) COMMENT '通訊地址',
    dietary_habit VARCHAR(100) DEFAULT '葷食' COMMENT '飲食習慣',
    bio TEXT COMMENT '自我介紹',
    email VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    emergency_contact VARCHAR(50) COMMENT '水域活動建議保留緊急聯絡人',
    emergency_phone VARCHAR(20),
    CONSTRAINT chk_id_number CHECK (id_number REGEXP '^[A-Z][1-2][0-9]{8}$'),
    CONSTRAINT chk_email CHECK (email LIKE '%@%')
);

-- 處理多值屬性：一個教練擁有多個專長
CREATE TABLE coach_specialties (
    id_number VARCHAR(10),
    specialty VARCHAR(50) NOT NULL COMMENT '專長項目，例如：SUP、自由潛水、衝浪、水上救生',
    PRIMARY KEY (id_number, specialty), -- 複合主鍵，確保同一個教練不會重複輸入相同專長
    FOREIGN KEY (id_number) REFERENCES coach(id_number) ON DELETE CASCADE
);

-- 處理多值屬性：一個教練擁有多張證照，並可記錄發證單位與有效期限
CREATE TABLE coach_licenses (
    license_id INT PRIMARY KEY AUTO_INCREMENT,
    id_number VARCHAR(10) NOT NULL,
    license_name VARCHAR(100) NOT NULL COMMENT '證照名稱，例如：PADI OW 專任教練、ISA 衝浪教練、體總救生員證',
    issue_org VARCHAR(100) COMMENT '發證單位 / 機構',
    expiry_date DATE COMMENT '證照效期截止日（水域證照通常有複訓期限）',
    FOREIGN KEY (id_number) REFERENCES coach(id_number) ON DELETE CASCADE
);

-- 2. 建立遊客表 (Tourists)
CREATE TABLE tourists (
    id_number VARCHAR(10) PRIMARY KEY,
    name VARCHAR(50) NOT NULL COMMENT '姓名',
    gender ENUM('男', '女') NOT NULL COMMENT '性別',
    birth_date DATE NOT NULL COMMENT '出生年月日',
    phone VARCHAR(20) NOT NULL COMMENT '聯絡電話',
    email VARCHAR(100),
    address VARCHAR(255) COMMENT '通訊地址',
    dietary_habit VARCHAR(100) DEFAULT '葷食' COMMENT '例如：葷食、全素、蛋奶素、海鮮過敏等',
    emergency_contact VARCHAR(50) COMMENT '水域活動建議保留緊急聯絡人',
    emergency_phone VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_id_number CHECK (id_number REGEXP '^[A-Z][1-2][0-9]{8}$'),
    CONSTRAINT chk_email CHECK (email LIKE '%@%')
);

-- 4. 建立報名紀錄表 (Bookings) - 處理遊客與課程的「多對多」關係
CREATE TABLE bookings (
    booking_id INT PRIMARY KEY AUTO_INCREMENT,
    session_id INT NOT NULL,
    tourist_id VARCHAR(10) NOT NULL,
    payment_status ENUM('未繳費', '已繳費', '已退款') DEFAULT '未繳費' COMMENT '繳費狀態',
    booking_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    insurance_status ENUM('未投保', '已投保') DEFAULT '未投保' COMMENT '保險作業狀態',
    FOREIGN KEY (session_id) REFERENCES course(session_id),
	FOREIGN KEY (tourist_id) REFERENCES tourists(id_number)
);

-- 5. 開課紀錄表 (Course) - 媒合教練與課程的多對多橋樑
CREATE TABLE course (
    session_id INT PRIMARY KEY AUTO_INCREMENT,
    item ENUM('SUP立槳', '獨木舟', '衝浪', '自由潛水', '水肺潛水') NOT NULL COMMENT '課程項目',
    instructor_id VARCHAR(10) NOT NULL, -- 多值
    start_time DATETIME NOT NULL,
    end_time DATETIME NOT NULL,
    price DECIMAL(10, 2) NOT NULL,
    difficulty_level ENUM('初階', '中階','中高階', '高階') DEFAULT '初階' COMMENT '難易度分類'
    capacity INT NOT NULL COMMENT '該場次人數上限',
    session_status ENUM('開放報名中', '已成團', '已客滿', '已取消', '已結束') DEFAULT '開放報名中' COMMENT '開課狀態',
    FOREIGN KEY (instructor_id) REFERENCES coach(id_number)
);

CREATE TABLE course_instructors (
    session_id INT NOT NULL,
    instructor_id VARCHAR(10) NOT NULL,
    PRIMARY KEY (session_id, instructor_id),
    FOREIGN KEY (session_id) REFERENCES course(session_id),
    FOREIGN KEY (instructor_id) REFERENCES coach(id_number)
);

-- 6. 器材表 (Equipment) - 紀錄工作室的資產
CREATE TABLE equipment (
    equipment_id INT PRIMARY KEY AUTO_INCREMENT COMMENT '器材唯一識別碼 (每件器材獨立編號)',
    name VARCHAR(100) NOT NULL COMMENT '器材名稱，例如：紅槳10尺6吋SUP板',
    category VARCHAR(50) NOT NULL COMMENT '器材類別，例如：SUP板、蛙鞋、防寒衣',
    purchase_date DATE NOT NULL COMMENT '購買日期',
    purchase_unit VARCHAR(100) COMMENT '購買單位 / 廠商 / 品牌',
    manager_id VARCHAR(10) COMMENT '負責人',
    useful_life_years INT COMMENT '使用年限 (年)',
    status ENUM('正常', '維修中', '報廢', '使用中') DEFAULT '正常' COMMENT '器材狀態',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 7. 器材租借紀錄表 (Equipment_Rentals) - 紀錄教練為了上課而租借的器材
CREATE TABLE equipment_rentals (
    session_id INT NOT NULL COMMENT '關聯到特定的開課場次',
    equipment_id INT NOT NULL,
    rental_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (session_id, equipment_id),
    FOREIGN KEY (session_id) REFERENCES course(session_id),
    FOREIGN KEY (equipment_id) REFERENCES equipment(equipment_id)
);
