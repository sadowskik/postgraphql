SELECT
  'namespace'     AS "kind",
  nsp.oid         AS "id",
  nsp.nspname     AS "name",
  dsc.description AS "description"
FROM
  pg_catalog.pg_namespace AS nsp
  LEFT JOIN pg_catalog.pg_description AS dsc ON dsc.objoid = nsp.oid
WHERE
  nsp.nspname = ANY ($1)
ORDER BY
  nsp.nspname
