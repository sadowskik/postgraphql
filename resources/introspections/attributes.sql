SELECT
  'attribute'     AS "kind",
  att.attrelid    AS "classId",
  att.attnum      AS "num",
  att.attname     AS "name",
  dsc.description AS "description",
  att.atttypid    AS "typeId",
  att.attnotnull  AS "isNotNull",
  att.atthasdef   AS "hasDefault"
FROM
  pg_catalog.pg_attribute AS att
  LEFT JOIN pg_catalog.pg_description AS dsc ON dsc.objoid = att.attrelid AND dsc.objsubid = att.attnum
WHERE
  att.attrelid = ANY ($1) AND
  att.attnum > 0 AND
  NOT att.attisdropped
ORDER BY
  att.attrelid, att.attnum
