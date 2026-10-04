-- 식전 -> 운동후, 식후 -> 취침전 데이터 업데이트
UPDATE public.blood_sugar_records
SET tag = '운동후'
WHERE tag = '식전';

UPDATE public.blood_sugar_records
SET tag = '취침전'
WHERE tag = '식후';

DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN (
        SELECT conname 
        FROM pg_constraint 
        WHERE conrelid = 'public.blood_sugar_records'::regclass 
          AND contype = 'c' 
          AND pg_get_constraintdef(oid) LIKE '%tag%'
    ) LOOP
        EXECUTE 'ALTER TABLE public.blood_sugar_records DROP CONSTRAINT ' || quote_ident(r.conname);
    END LOOP;
END $$;

ALTER TABLE public.blood_sugar_records
ADD CONSTRAINT blood_sugar_records_tag_check
CHECK (tag IS NULL OR tag IN ('공복', '운동후', '취침전', '예외'));
