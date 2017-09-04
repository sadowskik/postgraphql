SELECT DISTINCT ON (con.conrelid, con.conkey, con.confrelid, con.confkey)
  'constraint'             AS "kind",
  con.conname              AS "name",
  con.contype              AS "type",
  con.conrelid             AS "classId",
  nullif(con.confrelid, 0) AS "foreignClassId",
  con.conkey               AS "keyAttributeNums",
  con.confkey              AS "foreignKeyAttributeNums"
FROM
  pg_catalog.pg_constraint AS con
WHERE
  -- Only get constraints for classes we have selected.
  con.conrelid = ANY ($1) AND
  CASE
  -- If this is a foreign key constraint, we want to ensure that the
  -- foreign class is also in the list of classes we have already
  -- selected.
  WHEN con.contype = 'f'
    THEN con.confrelid = ANY ($1)
  -- Otherwise, this should be true.
  ELSE TRUE
  END AND
  -- We only want foreign key, primary key, and unique constraints. We
  -- made add support for more constraints in the future.
  con.contype IN ('f', 'p', 'u')
ORDER BY
  con.conrelid, con.conkey, con.confrelid, con.confkey, con.conname
