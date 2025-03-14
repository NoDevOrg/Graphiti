import GraphQL
import NIO

public protocol API {
    associatedtype Resolver
    associatedtype ContextType
    var resolver: Resolver { get }
    var schema: Schema<Resolver, ContextType> { get }
}

public extension API {
    func execute(
        request: String,
        context: ContextType,
        on eventLoopGroup: EventLoopGroup,
        variables: [String: Map] = [:],
        operationName: String? = nil,
        validationRules: [(ValidationContext) -> Visitor] = []
    ) -> EventLoopFuture<GraphQLResult> {
        return schema.execute(
            request: request,
            resolver: resolver,
            context: context,
            eventLoopGroup: eventLoopGroup,
            variables: variables,
            operationName: operationName,
            validationRules: validationRules
        )
    }

    func execute(
        request: GraphQLRequest,
        context: ContextType,
        on eventLoopGroup: EventLoopGroup,
        validationRules: [(ValidationContext) -> Visitor] = []
    ) -> EventLoopFuture<GraphQLResult> {
        return execute(
            request: request.query,
            context: context,
            on: eventLoopGroup,
            variables: request.variables,
            operationName: request.operationName,
            validationRules: validationRules
        )
    }

    func subscribe(
        request: String,
        context: ContextType,
        on eventLoopGroup: EventLoopGroup,
        variables: [String: Map] = [:],
        operationName: String? = nil,
        validationRules: [(ValidationContext) -> Visitor] = []
    ) -> EventLoopFuture<SubscriptionResult> {
        return schema.subscribe(
            request: request,
            resolver: resolver,
            context: context,
            eventLoopGroup: eventLoopGroup,
            variables: variables,
            operationName: operationName,
            validationRules: validationRules
        )
    }

    func subscribe(
        request: GraphQLRequest,
        context: ContextType,
        on eventLoopGroup: EventLoopGroup,
        validationRules: [(ValidationContext) -> Visitor] = []
    ) -> EventLoopFuture<SubscriptionResult> {
        return subscribe(
            request: request.query,
            context: context,
            on: eventLoopGroup,
            variables: request.variables,
            operationName: request.operationName,
            validationRules: validationRules
        )
    }
}

public extension API {
    @available(macOS 10.15, iOS 15, watchOS 8, tvOS 15, *)
    func execute(
        request: String,
        context: ContextType,
        on eventLoopGroup: EventLoopGroup,
        variables: [String: Map] = [:],
        operationName: String? = nil,
        validationRules: [(ValidationContext) -> Visitor] = []
    ) async throws -> GraphQLResult {
        return try await schema.execute(
            request: request,
            resolver: resolver,
            context: context,
            eventLoopGroup: eventLoopGroup,
            variables: variables,
            operationName: operationName,
            validationRules: validationRules
        ).get()
    }

    @available(macOS 10.15, iOS 15, watchOS 8, tvOS 15, *)
    func execute(
        request: GraphQLRequest,
        context: ContextType,
        on eventLoopGroup: EventLoopGroup,
        validationRules: [(ValidationContext) -> Visitor] = []
    ) async throws -> GraphQLResult {
        return try await execute(
            request: request.query,
            context: context,
            on: eventLoopGroup,
            variables: request.variables,
            operationName: request.operationName,
            validationRules: validationRules
        )
    }

    @available(macOS 10.15, iOS 15, watchOS 8, tvOS 15, *)
    func subscribe(
        request: String,
        context: ContextType,
        on eventLoopGroup: EventLoopGroup,
        variables: [String: Map] = [:],
        operationName: String? = nil,
        validationRules: [(ValidationContext) -> Visitor] = []
    ) async throws -> SubscriptionResult {
        return try await schema.subscribe(
            request: request,
            resolver: resolver,
            context: context,
            eventLoopGroup: eventLoopGroup,
            variables: variables,
            operationName: operationName,
            validationRules: validationRules
        ).get()
    }

    @available(macOS 10.15, iOS 15, watchOS 8, tvOS 15, *)
    func subscribe(
        request: GraphQLRequest,
        context: ContextType,
        on eventLoopGroup: EventLoopGroup,
        validationRules: [(ValidationContext) -> Visitor] = []
    ) async throws -> SubscriptionResult {
        return try await subscribe(
            request: request.query,
            context: context,
            on: eventLoopGroup,
            variables: request.variables,
            operationName: request.operationName,
            validationRules: validationRules
        )
    }
}
