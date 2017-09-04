WITH type_all AS (
    SELECT
      'type'                     AS "kind",
      typ.oid                    AS "id",
      typ.typname                AS "name",
      dsc.description            AS "description",
      typ.typnamespace           AS "namespaceId",
      -- We include the namespace name in types only because we select so
      -- many types that are outside of our core set of namespaces. Having
      -- the namespace name is super helpful when generating SQL, so
      -- conditionally having namespace names for types is a pain.
      nsp.nspname                AS "namespaceName",
      typ.typtype                AS "type",
      'X'                        AS "category",
      typ.typnotnull             AS "domainIsNotNull",
      nullif(typ.typelem, 0)     AS "arrayItemTypeId",
      nullif(typ.typrelid, 0)    AS "classId",
      nullif(typ.typbasetype, 0) AS "domainBaseTypeId",
      -- If this type is an enum type, let’s select all of its enum variants.
      --
      -- @see https://www.postgresql.org/docs/9.5/static/catalog-pg-enum.html
      NULL                       AS "enumVariants",
      -- not supported in Greenplum
      -- If this type is a range type, we want to select the sub type of the
      -- range.
      --
      -- @see https://www.postgresql.org/docs/9.6/static/catalog-pg-range.html
      NULL                       AS "rangeSubTypeId" -- not supported in Greenplum
    FROM
      pg_catalog.pg_type AS typ
      LEFT JOIN pg_catalog.pg_description AS dsc ON dsc.objoid = typ.oid
      LEFT JOIN pg_catalog.pg_namespace AS nsp ON nsp.oid = typ.typnamespace
)
SELECT *
FROM
  type_all AS typ
WHERE
  typ.id = ANY ($1) OR
  typ.id = ANY ($2) OR
  typ.id = ANY ($3) OR
  typ.id = ANY ($4) OR
  -- If this type is a base type for *any* domain type, we will include it
  -- in our selection. This may mean we fetch more types than we need, but
  -- the alternative is to do some funky SQL recursion which would be hard
  -- code to read. So we prefer code readability over selecting like 3 or
  -- 4 less type rows.
  --
  -- We also do this for range sub types and array item types.
  typ.id IN (SELECT "domainBaseTypeId" FROM type_all) OR
  --typ.id IN (SELECT "rangeSubTypeId" FROM type_all) OR
  typ.id IN (SELECT "arrayItemTypeId" FROM type_all)
ORDER BY
  "namespaceId", "name"
