import Graphiti
import GraphQL
import NIO
import XCTest

class PartialSchemaTests: XCTestCase {
    class BaseSchema: PartialSchema<StarWarsResolver, StarWarsContext> {
        @TypeDefinitions
        override var types: Types {
            Interface(Character.self) {
                Field("id", at: \.id)
                    .description("The id of the character.")
                Field("name", at: \.name)
                    .description("The name of the character.")
                Field("friends", at: \.friends)
                    .description(
                        "The friends of the character, or an empty list if they have none."
                    )
                Field("appearsIn", at: \.appearsIn)
                    .description("Which movies they appear in.")
                Field("secretBackstory", at: \.secretBackstory)
                    .description("All secrets about their past.")
            }

            Enum(Episode.self) {
                Value(.newHope)
                    .description("Released in 1977.")
                Value(.empire)
                    .description("Released in 1980.")
                Value(.jedi)
                    .description("Released in 1983.")
            }.description("One of the films in the Star Wars Trilogy.")
        }

        @FieldDefinitions
        override var query: Fields {
            Field("hero", at: StarWarsResolver.hero) {
                Argument("episode", at: \.episode)
                    .description(
                        "If omitted, returns the hero of the whole saga. If provided, returns the hero of that particular episode."
                    )
            }.description("Returns a hero based on the given episode.")
        }
    }

    class SearchSchema: PartialSchema<StarWarsResolver, StarWarsContext> {
        @TypeDefinitions
        override var types: Types {
            Type(Planet.self) {
                Field("id", at: \.id)
                Field("name", at: \.name)
                Field("diameter", at: \.diameter)
                Field("rotationPeriod", at: \.rotationPeriod)
                Field("orbitalPeriod", at: \.orbitalPeriod)
                Field("residents", at: \.residents)
            }.description(
                "A large mass, planet or planetoid in the Star Wars Universe, at the time of 0 ABY."
            )
            Type(Human.self, interfaces: [Character.self]) {
                Field("id", at: \.id)
                Field("name", at: \.name)
                Field("appearsIn", at: \.appearsIn)
                Field("homePlanet", at: \.homePlanet)
                Field("friends", at: Human.getFriends)
                    .description("The friends of the human, or an empty list if they have none.")
                Field("secretBackstory", at: Human.getSecretBackstory)
                    .description("Where are they from and how they came to be who they are.")
            }.description("A humanoid creature in the Star Wars universe.")
            Type(Droid.self, interfaces: [Character.self]) {
                Field("id", at: \.id)
                Field("name", at: \.name)
                Field("appearsIn", at: \.appearsIn)
                Field("primaryFunction", at: \.primaryFunction)
                Field("friends", at: Droid.getFriends)
                    .description("The friends of the droid, or an empty list if they have none.")
                Field("secretBackstory", at: Droid.getSecretBackstory)
                    .description("Where are they from and how they came to be who they are.")
            }.description("A mechanical creature in the Star Wars universe.")
            Union(SearchResult.self, members: Planet.self, Human.self, Droid.self)
        }

        @FieldDefinitions
        override var query: Fields {
            Field("human", at: StarWarsResolver.human) {
                Argument("id", at: \.id)
                    .description("Id of the human.")
            }
            Field("droid", at: StarWarsResolver.droid) {
                Argument("id", at: \.id)
                    .description("Id of the droid.")
            }
            Field("search", at: StarWarsResolver.search) {
                Argument("query", at: \.query)
                    .defaultValue("R2-D2")
            }
        }
    }

    func testPartialSchemaWithBuilder() throws {
        let group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)

        defer {
            try? group.syncShutdownGracefully()
        }

        let builder = SchemaBuilder(StarWarsResolver.self, StarWarsContext.self)

        builder.use(partials: [BaseSchema(), SearchSchema()])

        let schema = try builder.build()

        struct PartialSchemaTestAPI: API {
            let resolver: StarWarsResolver
            let schema: Schema<StarWarsResolver, StarWarsContext>
        }

        let api = PartialSchemaTestAPI(resolver: StarWarsResolver(), schema: schema)

        XCTAssertEqual(
            try api.execute(
                request: """
                query {
                    human(id: "1000") {
                        name
                    }
                }
                """,
                context: StarWarsContext(),
                on: group
            ).wait(),
            GraphQLResult(data: [
                "human": [
                    "name": "Luke Skywalker",
                ],
            ])
        )
    }

    func testPartialSchema() throws {
        let group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)

        defer {
            try? group.syncShutdownGracefully()
        }

        /// Double check if static func works and the types are inferred properly
        let schema = try Schema.create(from: [BaseSchema(), SearchSchema()])

        struct PartialSchemaTestAPI: API {
            let resolver: StarWarsResolver
            let schema: Schema<StarWarsResolver, StarWarsContext>
        }

        let api = PartialSchemaTestAPI(resolver: StarWarsResolver(), schema: schema)

        XCTAssertEqual(
            try api.execute(
                request: """
                query {
                    human(id: "1000") {
                        name
                    }
                }
                """,
                context: StarWarsContext(),
                on: group
            ).wait(),
            GraphQLResult(data: [
                "human": [
                    "name": "Luke Skywalker",
                ],
            ])
        )
    }

    func testPartialSchemaOutOfOrder() throws {
        let group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)

        defer {
            try? group.syncShutdownGracefully()
        }

        /// Double check if ordering of partial schema doesn't matter
        let schema = try Schema.create(from: [SearchSchema(), BaseSchema()])

        struct PartialSchemaTestAPI: API {
            let resolver: StarWarsResolver
            let schema: Schema<StarWarsResolver, StarWarsContext>
        }

        let api = PartialSchemaTestAPI(resolver: StarWarsResolver(), schema: schema)

        XCTAssertEqual(
            try api.execute(
                request: """
                query {
                    human(id: "1000") {
                        name
                    }
                }
                """,
                context: StarWarsContext(),
                on: group
            ).wait(),
            GraphQLResult(data: [
                "human": [
                    "name": "Luke Skywalker",
                ],
            ])
        )
    }

    func testInstancePartialSchema() throws {
        let baseSchema = PartialSchema<StarWarsResolver, StarWarsContext>(
            types: {
                Interface(Character.self) {
                    Field("id", at: \.id)
                        .description("The id of the character.")
                    Field("name", at: \.name)
                        .description("The name of the character.")
                    Field("friends", at: \.friends)
                        .description(
                            "The friends of the character, or an empty list if they have none."
                        )
                    Field("appearsIn", at: \.appearsIn)
                        .description("Which movies they appear in.")
                    Field("secretBackstory", at: \.secretBackstory)
                        .description("All secrets about their past.")
                }

                Enum(Episode.self) {
                    Value(.newHope)
                        .description("Released in 1977.")
                    Value(.empire)
                        .description("Released in 1980.")
                    Value(.jedi)
                        .description("Released in 1983.")
                }.description("One of the films in the Star Wars Trilogy.")
            },
            query: {
                Field("hero", at: StarWarsResolver.hero) {
                    Argument("episode", at: \.episode)
                        .description(
                            "If omitted, returns the hero of the whole saga. If provided, returns the hero of that particular episode."
                        )
                }.description("Returns a hero based on the given episode.")
            }
        )

        let searchSchema = PartialSchema<StarWarsResolver, StarWarsContext>(
            types: {
                Type(Planet.self) {
                    Field("id", at: \.id)
                    Field("name", at: \.name)
                    Field("diameter", at: \.diameter)
                    Field("rotationPeriod", at: \.rotationPeriod)
                    Field("orbitalPeriod", at: \.orbitalPeriod)
                    Field("residents", at: \.residents)
                }.description(
                    "A large mass, planet or planetoid in the Star Wars Universe, at the time of 0 ABY."
                )
                Type(Human.self, interfaces: [Character.self]) {
                    Field("id", at: \.id)
                    Field("name", at: \.name)
                    Field("appearsIn", at: \.appearsIn)
                    Field("homePlanet", at: \.homePlanet)
                    Field("friends", at: Human.getFriends)
                        .description(
                            "The friends of the human, or an empty list if they have none."
                        )
                    Field("secretBackstory", at: Human.getSecretBackstory)
                        .description("Where are they from and how they came to be who they are.")
                }.description("A humanoid creature in the Star Wars universe.")
                Type(Droid.self, interfaces: [Character.self]) {
                    Field("id", at: \.id)
                    Field("name", at: \.name)
                    Field("appearsIn", at: \.appearsIn)
                    Field("primaryFunction", at: \.primaryFunction)
                    Field("friends", at: Droid.getFriends)
                        .description(
                            "The friends of the droid, or an empty list if they have none."
                        )
                    Field("secretBackstory", at: Droid.getSecretBackstory)
                        .description("Where are they from and how they came to be who they are.")
                }.description("A mechanical creature in the Star Wars universe.")
                Union(SearchResult.self, members: Planet.self, Human.self, Droid.self)
            },
            query: {
                Field("human", at: StarWarsResolver.human) {
                    Argument("id", at: \.id)
                        .description("Id of the human.")
                }
                Field("droid", at: StarWarsResolver.droid) {
                    Argument("id", at: \.id)
                        .description("Id of the droid.")
                }
                Field("search", at: StarWarsResolver.search) {
                    Argument("query", at: \.query)
                        .defaultValue("R2-D2")
                }
            }
        )

        let group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)

        defer {
            try? group.syncShutdownGracefully()
        }

        /// Double check if ordering of partial schema doesn't matter
        let schema = try Schema.create(from: [searchSchema, baseSchema])

        struct PartialSchemaTestAPI: API {
            let resolver: StarWarsResolver
            let schema: Schema<StarWarsResolver, StarWarsContext>
        }

        let api = PartialSchemaTestAPI(resolver: StarWarsResolver(), schema: schema)

        XCTAssertEqual(
            try api.execute(
                request: """
                query {
                    human(id: "1000") {
                        name
                    }
                }
                """,
                context: StarWarsContext(),
                on: group
            ).wait(),
            GraphQLResult(data: [
                "human": [
                    "name": "Luke Skywalker",
                ],
            ])
        )
    }
}
