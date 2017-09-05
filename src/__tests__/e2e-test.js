import {Pool} from 'pg'
import {graphql} from 'graphql'

import createPostGraphQLSchema from '../postgraphql/schema/createPostGraphQLSchema'
import {withPostGraphQLContext} from '../postgraphql'

// This test suite can be flaky. Increase it’s timeout.
jasmine.DEFAULT_TIMEOUT_INTERVAL = 1000 * 2000

test('integration', async () => {

  const pool = new Pool({
    user: 'devuser',
    host: 'localhost',
    database: 'devdb',
    password: 'devpass',
    port: 54321,
  })

  const schema = await createPostGraphQLSchema(
    pool,
    ['dp', 'dtcm'],
    {
      graphiql: true,
      graphqlRoute: '/graphql',
      graphiqlRoute: '/graphiql',
      disableDefaultMutations: true
    })


  const query = "{\n" +
    "  allTrafficIncidents {\n" +
    "    nodes {\n" +
    "      acciId\n" +
    "      acciTime\n" +
    "      acciX\n" +
    "      acciY\n" +
    "      acciNum\n" +
    "      uploadTimestamp\n" +
    "      uploadIngestionId\n" +
    "    }\n" +
    "  }\n" +
    "}"

  const result = await withPostGraphQLContext({pgPool: pool},
    async context => {
      // You execute your GraphQL query in this function with the provided `context` object.
      // The `context` object will not work for a GraphQL execution outside of this function.
      return await graphql(
        schema, // This is the schema we created with `createPostGraphQLSchema`.
        query,
        null,
        {...context}, // Here we use the `context` object that gets passed to this callback.
        null,
        null,
      )
    }
  )

  expect(result.errors).toBeUndefined()
})
