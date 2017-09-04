import {resolve as resolvePath} from 'path'
import {readFile} from 'fs'
import {Client, Pool} from 'pg'
import * as minify from 'pg-minify'
import PgCatalog from './PgCatalog'
import PgCatalogNamespace from './object/PgCatalogNamespace'
import PgCatalogProcedure from './object/PgCatalogProcedure'
import PgCatalogClass from './object/PgCatalogClass'
import PgCatalogAttribute from './object/PgCatalogAttribute'
import PgCatalogType from './object/PgCatalogType'
import PgCatalogConstraint from './object/PgCatalogConstraint'
import PgCatalogObject from './object/PgCatalogObject'

async function introspectQuery(queryName: String): Promise<string> {
  return new Promise<string>((resolve, reject) => {

    const path = `../../../resources/introspections/${queryName}.sql`

    readFile(resolvePath(__dirname, path), (error, data) => {
      if (error) reject(error)
      else resolve(minify(data.toString()))
    })
  })
}

/**
 * Takes a Postgres client and introspects it, returning an instance of
 * `PgObjects` which can then be consumed. Note that some translation is done
 * from the raw Postgres catalog to the friendlier `PgObjects` interface.
 */
export default async function introspectDatabase(client: Pool | Client, schemas: Array<string>): Promise<PgCatalog> {

  const namespaces = await getNamespaces(client, schemas)
  const procedures = await getProcedures(client, namespaces)
  const classes = await getClasses(client, namespaces, procedures)
  const attributes = await getAttributes(client, classes)
  const types = await getTypes(client, classes, attributes, procedures)
  const constraints = await getConstraints(client, namespaces, classes)

  const objects = (namespaces as Array<PgCatalogObject>)
    .concat(procedures)
    .concat(classes)
    .concat(attributes)
    .concat(types)
    .concat(constraints)

  return new PgCatalog(objects)
}

async function getNamespaces(client: Pool | Client, schemas: Array<string>): Promise<Array<PgCatalogNamespace>> {

  const result = await client.query({
    name: 'namespacesIntrospection',
    text: await introspectQuery('namespaces'),
    values: [schemas],
  })

  return result.rows.map(object => object as PgCatalogNamespace)
}

async function getProcedures(client: Pool | Client, namespaces: Array<PgCatalogNamespace>): Promise<Array<PgCatalogProcedure>> {

  const result = await client.query({
    name: 'proceduresIntrospection',
    text: await introspectQuery('procedures'),
    values: [namespaces.map(ns => ns.id)],
  })

  return result.rows.map(object => object as PgCatalogProcedure)
}

async function getClasses(client: Pool | Client, namespaces: Array<PgCatalogNamespace>, procedures: Array<PgCatalogProcedure>): Promise<Array<PgCatalogClass>> {

  const result = await client.query({
    name: 'classesIntrospection',
    text: await introspectQuery('classes'),
    values: [
      namespaces.map(ns => ns.id),
      procedures.map(ns => ns.returnTypeId),
      procedures.map(ns => ns.argTypeIds)],
  })

  return result.rows.map(object => object as PgCatalogClass)
}

async function getAttributes(client: Pool | Client, classes: Array<PgCatalogClass>): Promise<Array<PgCatalogAttribute>> {

  const result = await client.query({
    name: 'attributesIntrospection',
    text: await introspectQuery('attributes'),
    values: [classes.map(ns => ns.id)],
  })

  return result.rows.map(object => object as PgCatalogAttribute)
}

async function getTypes(client: Pool | Client, classes: Array<PgCatalogClass>, attributes: Array<PgCatalogAttribute>, procedures: Array<PgCatalogProcedure>): Promise<Array<PgCatalogType>> {

  const result = await client.query({
    name: 'typesIntrospection',
    text: await introspectQuery('types'),
    values: [
      classes.map(ns => ns.typeId),
      attributes.map(attr => attr.typeId),
      procedures.map(proc => proc.returnTypeId),
      procedures.map(proc => proc.argTypeIds),
    ],
  })

  return result.rows.map(object => object as PgCatalogType)
}

async function getConstraints(client: Pool | Client, namespaces: Array<PgCatalogNamespace>, classes: Array<PgCatalogClass>): Promise<Array<PgCatalogConstraint>> {

  const classesFromNamespaces = classes.filter(clazz => namespaces.find(ns => ns.id === clazz.namespaceId))

  const result = await client.query({
    name: 'constraintsIntrospection',
    text: await introspectQuery('constraints'),
    values: [classesFromNamespaces.map(clazz => clazz.id)],
  })

  return result.rows.map(object => object as PgCatalogConstraint)
}
