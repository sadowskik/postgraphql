SELECT
  'class'                                                                                    AS "kind",
  rel.oid                                                                                    AS "id",
  rel.relname                                                                                AS "name",
  dsc.description                                                                            AS "description",
  rel.relnamespace                                                                           AS "namespaceId",
  rel.reltype                                                                                AS "typeId",
  -- Here we determine whether or not we can use this class in a
  -- `SELECT`’s `FROM` clause. In order to determine this we look at them
  -- `relkind` column, if it is `i` (index) or `c` (composite), we cannot
  -- select this class. Otherwise we can.
  rel.relkind NOT IN ('i', 'c')                                                              AS "isSelectable",
  -- Here we are determining whether we can insert/update/delete a class.
  -- This is helpful as it lets us detect non-updatable views and then
  -- exclude them from being inserted/updated/deleted into. For more info
  -- on how `pg_catalog.pg_relation_is_updatable` works:
  --
  -- - https://www.postgresql.org/message-id/CAEZATCV2_qN9P3zbvADwME_TkYf2gR_X2cLQR4R+pqkwxGxqJg@mail.gmail.com
  -- - https://github.com/postgres/postgres/blob/2410a2543e77983dab1f63f48b2adcd23dba994e/src/backend/utils/adt/misc.c#L684
  -- - https://github.com/postgres/postgres/blob/3aff33aa687e47d52f453892498b30ac98a296af/src/backend/rewrite/rewriteHandler.c#L2351
  FALSE AS "isInsertable",
  FALSE AS "isUpdatable",
  FALSE AS "isDeletable"
FROM
  pg_catalog.pg_class AS rel
  LEFT JOIN pg_catalog.pg_description AS dsc ON dsc.objoid = rel.oid AND dsc.objsubid = 0
WHERE
  -- Select classes that are in our namespace, or are referenced in a
  -- procedure.
  (
    rel.relnamespace = ANY ($1) OR
    rel.reltype = ANY ($2) OR
    rel.reltype = ANY ($3)
  ) AND
  -- rel.relpersistence IN ('p') AND
  rel.relkind IN ('r', 'v', 'm', 'c', 'f')
ORDER BY
  rel.relnamespace, rel.relname
