//
//  ChatWithAnyoneTests.swift
//  ChatWithAnyoneTests
//
//  Created by Ryan Imgrund on 2025-07-30.
//

import Testing
@testable import ChatWithAnyone

struct ChatWithAnyoneTests {

    @Test func personaSessionRoundTripsThroughJSON() async throws {
        let persona = Persona(
            id: UUID(),
            age: 42,
            gender: "Female",
            language: "English",
            country: "Canada",
            city: "Hamilton",
            personality: PersonalityProfile(friendliness: 0.8, humor: 0.4, optimism: 0.7, energy: 0.6),
            funPersonality: [
                FunPersonalityTrait(name: "Curiosity", value: 0.9),
                FunPersonalityTrait(name: "Warmth", value: 0.75)
            ],
            responseType: "Teacherly",
            creationDate: Date(timeIntervalSince1970: 1_800_000_000),
            backstory: "She enjoys helping people practice difficult conversations."
        )
        let session = SavedPersonaSession(
            id: persona.id,
            persona: persona,
            chatHistory: [
                ChatMessage(id: UUID(), isUser: true, text: "Hello"),
                ChatMessage(id: UUID(), isUser: false, text: "Hi there.")
            ]
        )

        let encoded = try JSONEncoder().encode([session])
        let decoded = try JSONDecoder().decode([SavedPersonaSession].self, from: encoded)

        #expect(decoded == [session])
    }

    @Test func chatMessageKeepsSpeakerAndText() async throws {
        let message = ChatMessage(id: UUID(), isUser: true, text: "I need practice.")

        #expect(message.isUser)
        #expect(message.text == "I need practice.")
    }

}
