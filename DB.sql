<<<<<<< HEAD
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
    email VARCHAR(100) UNIQUE COMMENT '電子信箱 (登入帳號)',
    password VARCHAR(100) DEFAULT 'password123' COMMENT '登入密碼',
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
    course_name VARCHAR(100) NOT NULL COMMENT '課程名稱',
    item ENUM('SUP立槳', '獨木舟', '衝浪', '自由潛水', '水肺潛水') NOT NULL COMMENT '課程項目',
    instructor_id VARCHAR(10) NOT NULL, -- 多值
    start_time DATETIME NOT NULL,
    end_time DATETIME NOT NULL,
    price DECIMAL(10, 2) NOT NULL,
    difficulty_level ENUM('初階', '中階','中高階', '高階') DEFAULT '初階' COMMENT '難易度分類',
    capacity INT NOT NULL COMMENT '該場次人數上限',
    session_status ENUM('開放報名中', '已成團', '已客滿', '已取消', '已結束') DEFAULT '開放報名中' COMMENT '開課狀態',
    course_type VARCHAR(20) DEFAULT '單次活動' CHECK (course_type IN ('常態班', '單次活動')) COMMENT '課程類型',
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

-- 9. 教練可接客時段表 (Coach Availability) - 用於常態班預約
CREATE TABLE coach_availability (
    availability_id INT PRIMARY KEY AUTO_INCREMENT,
    coach_id VARCHAR(10) NOT NULL COMMENT '教練身分證字號',
    available_date DATE NOT NULL COMMENT '可接客日期',
    time_slot VARCHAR(20) NOT NULL COMMENT '時段，例如：上午、下午、全天',
    status VARCHAR(20) DEFAULT '開放預約' CHECK (status IN ('開放預約', '已預約', '停用')) COMMENT '預約狀態',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (coach_id) REFERENCES coach(id_number) ON DELETE CASCADE
);

-- ==========================================================
-- 8. 建立遊客項目等級表 (Tourist Item Levels) - 處理遊客在各水域項目的等級
-- ==========================================================
CREATE TABLE tourist_item_levels (
    tourist_id VARCHAR(10) NOT NULL,
    item VARCHAR(50) NOT NULL,
    level VARCHAR(10) NOT NULL,
    PRIMARY KEY (tourist_id, item),
    FOREIGN KEY (tourist_id) REFERENCES tourists(id_number) ON DELETE CASCADE,
    CONSTRAINT chk_level CHECK (level IN ('初階', '中階', '中高階', '高階'))
);

-- 10. 遊客身體健康調查表 (Tourist Health Survey)
CREATE TABLE tourist_health_survey (
    survey_id INT PRIMARY KEY AUTO_INCREMENT,
    tourist_id VARCHAR(10) NOT NULL,
    swimming_ability VARCHAR(50) COMMENT '游泳能力',
    sup_experience VARCHAR(50) COMMENT 'SUP操作經驗',
    expectations TEXT COMMENT '活動期待',
    health_limitations VARCHAR(10) COMMENT '是否有身體限制',
    limitations_detail TEXT COMMENT '限制與建議細節',
    has_diseases TEXT COMMENT '現有或曾有疾病',
    recent_injuries VARCHAR(10) COMMENT '三年內受傷或手術',
    injuries_detail TEXT COMMENT '受傷部位與狀況',
    heat_illness VARCHAR(10) COMMENT '曾經中暑',
    heat_illness_detail TEXT COMMENT '中暑狀況與處置',
    allergies VARCHAR(10) COMMENT '過敏問題',
    allergies_detail TEXT COMMENT '服藥或藥物過敏細節',
    other_conditions TEXT COMMENT '其他健康狀況',
    covid_symptoms TEXT COMMENT '14天內新冠不適症狀',
    travel_history VARCHAR(10) COMMENT '28天內國外旅遊史',
    quarantine_type VARCHAR(100) COMMENT '返國檢疫措施',
    crowded_places VARCHAR(10) COMMENT '近期出入群聚場所',
    crowded_places_detail TEXT COMMENT '出入時間地點細節',
    covid_contact VARCHAR(10) COMMENT '是否與確診者接觸',
    signature_health VARCHAR(100) COMMENT '健康聲明書簽署',
    signature_consent VARCHAR(100) COMMENT '個人同意書簽署',
    fill_date DATE DEFAULT CURRENT_DATE COMMENT '填寫日期',
    FOREIGN KEY (tourist_id) REFERENCES tourists(id_number) ON DELETE CASCADE
);

-- 建立自動更新遊客等級的 Function
CREATE OR REPLACE FUNCTION update_tourist_level(t_id VARCHAR, c_item VARCHAR)
RETURNS VOID AS $$
DECLARE
    count_all INT;
    count_beginner INT;
    count_intermediate INT;
    count_intermediate_advanced INT;
    calculated_level VARCHAR(10);
BEGIN
    -- 計算該遊客在該項目中的有效預約總數（排除已退款）
    SELECT COUNT(*) INTO count_all
    FROM bookings b
    JOIN course c ON b.session_id = c.session_id
    WHERE b.tourist_id = t_id 
      AND c.item::VARCHAR = c_item
      AND b.payment_status != '已退款';

    IF count_all = 0 THEN
        -- 若無任何參與紀錄，則不產生/刪除該項目的等級資料
        DELETE FROM tourist_item_levels
        WHERE tourist_id = t_id AND item = c_item;
    ELSE
        -- 計算初階參與次數
        SELECT COUNT(*) INTO count_beginner
        FROM bookings b
        JOIN course c ON b.session_id = c.session_id
        WHERE b.tourist_id = t_id 
          AND c.item::VARCHAR = c_item 
          AND c.difficulty_level = '初階'
          AND b.payment_status != '已退款';

        -- 計算中階參與次數
        SELECT COUNT(*) INTO count_intermediate
        FROM bookings b
        JOIN course c ON b.session_id = c.session_id
        WHERE b.tourist_id = t_id 
          AND c.item::VARCHAR = c_item 
          AND c.difficulty_level = '中階'
          AND b.payment_status != '已退款';

        -- 計算中高階參與次數
        SELECT COUNT(*) INTO count_intermediate_advanced
        FROM bookings b
        JOIN course c ON b.session_id = c.session_id
        WHERE b.tourist_id = t_id 
          AND c.item::VARCHAR = c_item 
          AND c.difficulty_level = '中高階'
          AND b.payment_status != '已退款';

        -- 升級邏輯：
        -- 1. 參與過第一次即為「初階」
        -- 2. 參與過 3 次初階升為「中階」
        -- 3. 參與過 3 次中階升為「中高階」
        -- 4. 參與過 3 次中高階升為「高階」
        calculated_level := '初階';
        IF count_beginner >= 3 THEN
            calculated_level := '中階';
            IF count_intermediate >= 3 THEN
                calculated_level := '中高階';
                IF count_intermediate_advanced >= 3 THEN
                    calculated_level := '高階';
                END IF;
            END IF;
        END IF;

        -- 寫入或更新等級
        INSERT INTO tourist_item_levels (tourist_id, item, level)
        VALUES (t_id, c_item, calculated_level)
        ON CONFLICT (tourist_id, item)
        DO UPDATE SET level = EXCLUDED.level;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- 建立 Trigger Function，在 bookings 增刪改時觸發
CREATE OR REPLACE FUNCTION trigger_update_tourist_level()
RETURNS TRIGGER AS $$
DECLARE
    v_item VARCHAR;
BEGIN
    IF (TG_OP = 'INSERT' OR TG_OP = 'UPDATE') THEN
        SELECT item::VARCHAR INTO v_item FROM course WHERE session_id = NEW.session_id;
        IF v_item IS NOT NULL THEN
            PERFORM update_tourist_level(NEW.tourist_id, v_item);
        END IF;
    END IF;
    
    IF (TG_OP = 'DELETE' OR TG_OP = 'UPDATE') THEN
        SELECT item::VARCHAR INTO v_item FROM course WHERE session_id = OLD.session_id;
        IF v_item IS NOT NULL THEN
            PERFORM update_tourist_level(OLD.tourist_id, v_item);
        END IF;
    END IF;
    
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- 註冊 Trigger 到 bookings 表
CREATE TRIGGER trg_bookings_update_level
AFTER INSERT OR UPDATE OR DELETE ON bookings
FOR EACH ROW
EXECUTE FUNCTION trigger_update_tourist_level();

-- ==========================================================
-- 10. 資料庫升級指令 (針對已建立原 Schema 之資料庫)
-- ==========================================================
-- ALTER TABLE tourists ADD COLUMN IF NOT EXISTS password VARCHAR(100) DEFAULT 'password123';
-- ALTER TABLE tourists ADD CONSTRAINT unique_email UNIQUE (email);
-- ALTER TABLE course ADD COLUMN IF NOT EXISTS course_type VARCHAR(20) DEFAULT '單次活動' CHECK (course_type IN ('常態班', '單次活動'));
-- CREATE TABLE IF NOT EXISTS coach_availability (
--     availability_id SERIAL PRIMARY KEY,
--     coach_id VARCHAR(10) NOT NULL REFERENCES coach(id_number) ON DELETE CASCADE,
--     available_date DATE NOT NULL,
--     time_slot VARCHAR(20) NOT NULL, -- '上午', '下午', '全天'
--     status VARCHAR(20) DEFAULT '開放預約' CHECK (status IN ('開放預約', '已預約', '停用')),
--     created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
-- );
-- ALTER TABLE coach_availability DISABLE ROW LEVEL SECURITY;
-- ALTER TABLE course ADD COLUMN IF NOT EXISTS course_name VARCHAR(100) DEFAULT '未命名課程';
-- CREATE TABLE IF NOT EXISTS tourist_health_survey (
--     survey_id SERIAL PRIMARY KEY,
--     tourist_id VARCHAR(10) NOT NULL REFERENCES tourists(id_number) ON DELETE CASCADE,
--     swimming_ability VARCHAR(50),
--     sup_experience VARCHAR(50),
--     expectations TEXT,
--     health_limitations VARCHAR(10),
--     limitations_detail TEXT,
--     has_diseases TEXT,
--     recent_injuries VARCHAR(10),
--     injuries_detail TEXT,
--     heat_illness VARCHAR(10),
--     heat_illness_detail TEXT,
--     allergies VARCHAR(10),
--     allergies_detail TEXT,
--     other_conditions TEXT,
--     covid_symptoms TEXT,
--     travel_history VARCHAR(10),
--     quarantine_type VARCHAR(100),
--     crowded_places VARCHAR(10),
--     crowded_places_detail TEXT,
--     covid_contact VARCHAR(10),
--     signature_health VARCHAR(100),
--     signature_consent VARCHAR(100),
--     fill_date DATE DEFAULT CURRENT_DATE
-- );
-- 3. 升級資訊：遊客資料庫新增登入資訊 (以 Email 為帳號，自訂英數密碼)
-- ALTER TABLE tourists ADD COLUMN IF NOT EXISTS email VARCHAR(100) UNIQUE COMMENT '電子信箱 (登入帳號)';
-- ALTER TABLE tourists ADD COLUMN IF NOT EXISTS password VARCHAR(100) DEFAULT 'password123' COMMENT '登入密碼';

-- 4. 建立購物車資料表 (Cart) 儲存使用者購物車內資料
-- CREATE TABLE IF NOT EXISTS cart (
--     id SERIAL PRIMARY KEY,
--     tourist_id VARCHAR(10) NOT NULL REFERENCES tourists(id_number) ON DELETE CASCADE,
--     session_id INT NOT NULL REFERENCES course(session_id) ON DELETE CASCADE,
--     created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
--     CONSTRAINT uq_tourist_session UNIQUE (tourist_id, session_id)
-- );
-- ALTER TABLE cart DISABLE ROW LEVEL SECURITY;

=======
<<<<<<< HEAD
<<<<<<< HEAD
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
=======
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
>>>>>>> b40615f112ee0474ceb12fd06d65c781bdd3787d
=======
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
    course_name VARCHAR(100) NOT NULL COMMENT '課程名稱',
    item ENUM('SUP立槳', '獨木舟', '衝浪', '自由潛水', '水肺潛水') NOT NULL COMMENT '課程項目',
    instructor_id VARCHAR(10) NOT NULL, -- 多值
    start_time DATETIME NOT NULL,
    end_time DATETIME NOT NULL,
    price DECIMAL(10, 2) NOT NULL,
    difficulty_level ENUM('初階', '中階','中高階', '高階') DEFAULT '初階' COMMENT '難易度分類',
    capacity INT NOT NULL COMMENT '該場次人數上限',
    session_status ENUM('開放報名中', '已成團', '已客滿', '已取消', '已結束') DEFAULT '開放報名中' COMMENT '開課狀態',
    course_type VARCHAR(20) DEFAULT '單次活動' CHECK (course_type IN ('常態班', '單次活動')) COMMENT '課程類型',
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

-- 9. 教練可接客時段表 (Coach Availability) - 用於常態班預約
CREATE TABLE coach_availability (
    availability_id INT PRIMARY KEY AUTO_INCREMENT,
    coach_id VARCHAR(10) NOT NULL COMMENT '教練身分證字號',
    available_date DATE NOT NULL COMMENT '可接客日期',
    time_slot VARCHAR(20) NOT NULL COMMENT '時段，例如：上午、下午、全天',
    status VARCHAR(20) DEFAULT '開放預約' CHECK (status IN ('開放預約', '已預約', '停用')) COMMENT '預約狀態',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (coach_id) REFERENCES coach(id_number) ON DELETE CASCADE
);

-- ==========================================================
-- 8. 建立遊客項目等級表 (Tourist Item Levels) - 處理遊客在各水域項目的等級
-- ==========================================================
CREATE TABLE tourist_item_levels (
    tourist_id VARCHAR(10) NOT NULL,
    item VARCHAR(50) NOT NULL,
    level VARCHAR(10) NOT NULL,
    PRIMARY KEY (tourist_id, item),
    FOREIGN KEY (tourist_id) REFERENCES tourists(id_number) ON DELETE CASCADE,
    CONSTRAINT chk_level CHECK (level IN ('初階', '中階', '中高階', '高階'))
);

-- 10. 遊客身體健康調查表 (Tourist Health Survey)
CREATE TABLE tourist_health_survey (
    survey_id INT PRIMARY KEY AUTO_INCREMENT,
    tourist_id VARCHAR(10) NOT NULL,
    swimming_ability VARCHAR(50) COMMENT '游泳能力',
    sup_experience VARCHAR(50) COMMENT 'SUP操作經驗',
    expectations TEXT COMMENT '活動期待',
    health_limitations VARCHAR(10) COMMENT '是否有身體限制',
    limitations_detail TEXT COMMENT '限制與建議細節',
    has_diseases TEXT COMMENT '現有或曾有疾病',
    recent_injuries VARCHAR(10) COMMENT '三年內受傷或手術',
    injuries_detail TEXT COMMENT '受傷部位與狀況',
    heat_illness VARCHAR(10) COMMENT '曾經中暑',
    heat_illness_detail TEXT COMMENT '中暑狀況與處置',
    allergies VARCHAR(10) COMMENT '過敏問題',
    allergies_detail TEXT COMMENT '服藥或藥物過敏細節',
    other_conditions TEXT COMMENT '其他健康狀況',
    covid_symptoms TEXT COMMENT '14天內新冠不適症狀',
    travel_history VARCHAR(10) COMMENT '28天內國外旅遊史',
    quarantine_type VARCHAR(100) COMMENT '返國檢疫措施',
    crowded_places VARCHAR(10) COMMENT '近期出入群聚場所',
    crowded_places_detail TEXT COMMENT '出入時間地點細節',
    covid_contact VARCHAR(10) COMMENT '是否與確診者接觸',
    signature_health VARCHAR(100) COMMENT '健康聲明書簽署',
    signature_consent VARCHAR(100) COMMENT '個人同意書簽署',
    fill_date DATE DEFAULT CURRENT_DATE COMMENT '填寫日期',
    FOREIGN KEY (tourist_id) REFERENCES tourists(id_number) ON DELETE CASCADE
);

-- 建立自動更新遊客等級的 Function
CREATE OR REPLACE FUNCTION update_tourist_level(t_id VARCHAR, c_item VARCHAR)
RETURNS VOID AS $$
DECLARE
    count_all INT;
    count_beginner INT;
    count_intermediate INT;
    count_intermediate_advanced INT;
    calculated_level VARCHAR(10);
BEGIN
    -- 計算該遊客在該項目中的有效預約總數（排除已退款）
    SELECT COUNT(*) INTO count_all
    FROM bookings b
    JOIN course c ON b.session_id = c.session_id
    WHERE b.tourist_id = t_id 
      AND c.item::VARCHAR = c_item
      AND b.payment_status != '已退款';

    IF count_all = 0 THEN
        -- 若無任何參與紀錄，則不產生/刪除該項目的等級資料
        DELETE FROM tourist_item_levels
        WHERE tourist_id = t_id AND item = c_item;
    ELSE
        -- 計算初階參與次數
        SELECT COUNT(*) INTO count_beginner
        FROM bookings b
        JOIN course c ON b.session_id = c.session_id
        WHERE b.tourist_id = t_id 
          AND c.item::VARCHAR = c_item 
          AND c.difficulty_level = '初階'
          AND b.payment_status != '已退款';

        -- 計算中階參與次數
        SELECT COUNT(*) INTO count_intermediate
        FROM bookings b
        JOIN course c ON b.session_id = c.session_id
        WHERE b.tourist_id = t_id 
          AND c.item::VARCHAR = c_item 
          AND c.difficulty_level = '中階'
          AND b.payment_status != '已退款';

        -- 計算中高階參與次數
        SELECT COUNT(*) INTO count_intermediate_advanced
        FROM bookings b
        JOIN course c ON b.session_id = c.session_id
        WHERE b.tourist_id = t_id 
          AND c.item::VARCHAR = c_item 
          AND c.difficulty_level = '中高階'
          AND b.payment_status != '已退款';

        -- 升級邏輯：
        -- 1. 參與過第一次即為「初階」
        -- 2. 參與過 3 次初階升為「中階」
        -- 3. 參與過 3 次中階升為「中高階」
        -- 4. 參與過 3 次中高階升為「高階」
        calculated_level := '初階';
        IF count_beginner >= 3 THEN
            calculated_level := '中階';
            IF count_intermediate >= 3 THEN
                calculated_level := '中高階';
                IF count_intermediate_advanced >= 3 THEN
                    calculated_level := '高階';
                END IF;
            END IF;
        END IF;

        -- 寫入或更新等級
        INSERT INTO tourist_item_levels (tourist_id, item, level)
        VALUES (t_id, c_item, calculated_level)
        ON CONFLICT (tourist_id, item)
        DO UPDATE SET level = EXCLUDED.level;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- 建立 Trigger Function，在 bookings 增刪改時觸發
CREATE OR REPLACE FUNCTION trigger_update_tourist_level()
RETURNS TRIGGER AS $$
DECLARE
    v_item VARCHAR;
BEGIN
    IF (TG_OP = 'INSERT' OR TG_OP = 'UPDATE') THEN
        SELECT item::VARCHAR INTO v_item FROM course WHERE session_id = NEW.session_id;
        IF v_item IS NOT NULL THEN
            PERFORM update_tourist_level(NEW.tourist_id, v_item);
        END IF;
    END IF;
    
    IF (TG_OP = 'DELETE' OR TG_OP = 'UPDATE') THEN
        SELECT item::VARCHAR INTO v_item FROM course WHERE session_id = OLD.session_id;
        IF v_item IS NOT NULL THEN
            PERFORM update_tourist_level(OLD.tourist_id, v_item);
        END IF;
    END IF;
    
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- 註冊 Trigger 到 bookings 表
CREATE TRIGGER trg_bookings_update_level
AFTER INSERT OR UPDATE OR DELETE ON bookings
FOR EACH ROW
EXECUTE FUNCTION trigger_update_tourist_level();

-- ==========================================================
-- 10. 資料庫升級指令 (針對已建立原 Schema 之資料庫)
-- ==========================================================
-- ALTER TABLE course ADD COLUMN IF NOT EXISTS course_type VARCHAR(20) DEFAULT '單次活動' CHECK (course_type IN ('常態班', '單次活動'));
-- CREATE TABLE IF NOT EXISTS coach_availability (
--     availability_id SERIAL PRIMARY KEY,
--     coach_id VARCHAR(10) NOT NULL REFERENCES coach(id_number) ON DELETE CASCADE,
--     available_date DATE NOT NULL,
--     time_slot VARCHAR(20) NOT NULL, -- '上午', '下午', '全天'
--     status VARCHAR(20) DEFAULT '開放預約' CHECK (status IN ('開放預約', '已預約', '停用')),
--     created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
-- );
-- ALTER TABLE coach_availability DISABLE ROW LEVEL SECURITY;
-- ALTER TABLE course ADD COLUMN IF NOT EXISTS course_name VARCHAR(100) DEFAULT '未命名課程';
-- CREATE TABLE IF NOT EXISTS tourist_health_survey (
--     survey_id SERIAL PRIMARY KEY,
--     tourist_id VARCHAR(10) NOT NULL REFERENCES tourists(id_number) ON DELETE CASCADE,
--     swimming_ability VARCHAR(50),
--     sup_experience VARCHAR(50),
--     expectations TEXT,
--     health_limitations VARCHAR(10),
--     limitations_detail TEXT,
--     has_diseases TEXT,
--     recent_injuries VARCHAR(10),
--     injuries_detail TEXT,
--     heat_illness VARCHAR(10),
--     heat_illness_detail TEXT,
--     allergies VARCHAR(10),
--     allergies_detail TEXT,
--     other_conditions TEXT,
--     covid_symptoms TEXT,
--     travel_history VARCHAR(10),
--     quarantine_type VARCHAR(100),
--     crowded_places VARCHAR(10),
--     crowded_places_detail TEXT,
--     covid_contact VARCHAR(10),
--     signature_health VARCHAR(100),
--     signature_consent VARCHAR(100),
--     fill_date DATE DEFAULT CURRENT_DATE
-- );
-- ALTER TABLE tourist_health_survey DISABLE ROW LEVEL SECURITY;
>>>>>>> d3dff0859243c42fb7fc326197d8399e5aaae057
>>>>>>> 17d672db8d0f5e3adbec5259b7c93e0fce60fe64
