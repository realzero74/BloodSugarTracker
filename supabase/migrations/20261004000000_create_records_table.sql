-- 혈당 기록 테이블 생성 (Blood Sugar Records)
CREATE TABLE public.blood_sugar_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE, -- 사용자 구분 (Auth 연동 시)
    sugar_value INTEGER NOT NULL CHECK (sugar_value > 0), -- 혈당 수치 (mg/dL)
    measure_time TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(), -- 측정 시간
    tag VARCHAR(20) CHECK (tag IN ('공복', '식전', '식후')), -- 상태 태그
    memo TEXT, -- 선택 메모
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- RLS (Row Level Security) 설정 (간단히 누구나 CRUD 할 수 있도록 하거나, 인증유저만 접근하도록 설정. 현재는 더미/초기 테스트를 위해 PUBLIC 허용)
ALTER TABLE public.blood_sugar_records ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow all actions for everyone (Testing)" ON public.blood_sugar_records
    FOR ALL
    USING (true)
    WITH CHECK (true);
