SELECT
  'procedure'                                   AS "kind",
  pro.proname                                   AS "name",
  dsc.description                               AS "description",
  pro.pronamespace                              AS "namespaceId",
  pro.proisstrict                               AS "isStrict",
  pro.proretset                                 AS "returnsSet",
  CASE
  WHEN pro.provolatile = 'i'
    THEN TRUE
  WHEN pro.provolatile = 's'
    THEN TRUE
  ELSE FALSE
  END                                           AS "isStable",
  pro.prorettype                                AS "returnTypeId",
  coalesce(pro.proallargtypes, pro.proargtypes) AS "argTypeIds",
  NULL                                          AS "argNames",
  NULL                                          AS "argDefaultsNum"
FROM
  pg_catalog.pg_proc AS pro
  LEFT JOIN pg_catalog.pg_description AS dsc ON dsc.objoid = pro.oid
WHERE
  pro.pronamespace = ANY ($1) AND
  -- Currently we don’t support functions with variadic arguments. In the
  -- future we may, but for now let’s just ignore functions with variadic
  -- arguments.
  -- TODO: Variadic arguments.
  -- pro.provariadic = 0 and
  -- Filter our aggregate functions and window functions.
  pro.proisagg = FALSE AND
  -- pro.proiswindow = false and
  -- We want to make sure the argument mode for all of our arguments is
  -- `IN` which means `proargmodes` will be null.
  pro.proargmodes IS NULL AND
  -- Do not select procedures that create range types. These are utility
  -- functions that really don’t need to be exposed in an API.
  pro.proname NOT IN (SELECT typ.typname
                      FROM pg_catalog.pg_type AS typ
                      WHERE typ.typtype = 'r' AND typ.typnamespace = pro.pronamespace) AND
  -- We also don’t want procedures that have been defined in our namespace
  -- twice. This leads to duplicate fields in the API which throws an
  -- error. In the future we may support this case. For now though, it is
  -- too complex.
  (SELECT count(pro2.*)
   FROM pg_catalog.pg_proc AS pro2
   WHERE pro2.pronamespace = pro.pronamespace AND pro2.proname = pro.proname) = 1
ORDER BY
  pro.pronamespace, pro.proname
