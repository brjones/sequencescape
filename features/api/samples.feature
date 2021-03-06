@api @json @sample @single-sign-on @new-api
Feature: Access samples through the API
  In order to actually be able to do anything useful
  As an authenticated user of the API
  I want to be able to create, read and update individual samples through their UUID
  And I want to be able to perform other operations to individual samples
  And I want to be able to do all of this only knowing the UUID of a sample
  And I understand I will never be able to delete a sample through its UUID

  Background:
    Given all of this is happening at exactly "23-Oct-2010 23:00:00+01:00"

    Given all HTTP requests to the API have the cookie "WTSISignOn" set to "I-am-authenticated"
    And the WTSI single sign-on service recognises "I-am-authenticated" as "John Smith"

    Given I am using the latest version of the API

  # "NOTE": we cannot predefine the ID here so we ignore it in the uuids_to_ids map
  @create
  Scenario: Creating a sample
    Given the UUID of the next sample created will be "00000000-1111-2222-3333-444444444444"

    When I POST the following JSON to the API path "/samples":
      """
      {
        "sample": {
          "name": "testing_the_api"
        }
      }
      """
    Then the HTTP response should be "201 Created"
    And the JSON should match the following for the specified fields:
      """
      {
        "sample": {
          "actions": {
            "read": "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444",
            "update": "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444"
          },

          "uuid": "00000000-1111-2222-3333-444444444444",
          "name": "testing_the_api"
        },
        "uuids_to_ids": {
        }
      }
      """

  @create @error 
  Scenario Outline: Creating a sample which results in an error
    When I POST the following JSON to the API path "/samples":
      """
      {
        "sample": {
          "<field>": <value>
        }
      }
      """
    Then the HTTP response should be "422 Unprocessable Entity"
    And the JSON should match the following for the specified fields:
      """
      {
        "content": {
          "<field>": [<errors>]
        }
      }
      """

    Scenarios:
      | field      | value            | errors                                                                    |
      | name       | null             | "can't be blank", "Sample name can only contain letters, numbers, _ or -" |
      | name       | ""               | "can't be blank", "Sample name can only contain letters, numbers, _ or -" |
      | gender     | "Weird"          | "is not included in the list"                                             |
      | sra_hold   | "Please"         | "is not included in the list"                                             |
      | dna_source | "Blood donation" | "is not included in the list"                                             |

  @update @error
  Scenario Outline: Updating the sample associated with the UUID which gives an error
    Given a sample called "testing_the_api_exists" with ID 1
    And the UUID for the sample with ID 1 is "00000000-1111-2222-3333-444444444444"

    When I PUT the following JSON to the API path "/00000000-1111-2222-3333-444444444444":
      """
      {
        "sample": {
          "<field>": <value>
        }
      }
      """
    Then the HTTP response should be "422 Unprocessable Entity"
    And the JSON should be:
      """
      {
        "content": {
          "<field>": [<errors>]
        }
      }
      """

    Scenarios:
      | field      | value            | errors                                                                                         |
      | name       | null             | "can't be blank", "cannot be changed", "Sample name can only contain letters, numbers, _ or -" |
      | name       | ""               | "can't be blank", "cannot be changed", "Sample name can only contain letters, numbers, _ or -" |
      | name       | "jolly_nice"     | "cannot be changed"                                                                            |
      | gender     | "Weird"          | "is not included in the list"                                                                  |
      | sra_hold   | "Please"         | "is not included in the list"                                                                  |
      | dna_source | "Blood donation" | "is not included in the list"                                                                  |

  @update
  Scenario: Updating the sample associated with the UUID
    Given a sample called "testing_the_api_exists" with ID 1
    And the UUID for the sample with ID 1 is "00000000-1111-2222-3333-444444444444"

    When I PUT the following JSON to the API path "/00000000-1111-2222-3333-444444444444":
      """
      {
        "sample": {

        }
      }
      """
    Then the HTTP response should be "200 OK"
    And the JSON should match the following for the specified fields:
      """
      {
        "sample": {
          "actions": {
            "read": "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444",
            "update": "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444"
          },

          "uuid": "00000000-1111-2222-3333-444444444444"
        },
        "uuids_to_ids": {
          "00000000-1111-2222-3333-444444444444": 1
        }
      }
      """

  @read @error
  Scenario: Reading the JSON for a UUID that does not exist
    When I GET the API path "/00000000-1111-2222-3333-444444444444"
    Then the HTTP response should be "404 Not Found"
    And the JSON should be:
      """
      {
        "general": [ "UUID does not exist" ]
      }
      """

  @read
  Scenario: Reading the JSON for a UUID
    Given a sample called "testing_the_api_exists" with ID 1
    And the UUID for the sample with ID 1 is "00000000-1111-2222-3333-444444444444"

    When I GET the API path "/00000000-1111-2222-3333-444444444444"
    Then the HTTP response should be "200 OK"
    And the JSON should match the following for the specified fields:
      """
      {
        "sample": {
          "actions": {
            "read": "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444",
            "update": "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444"
          },

          "uuid": "00000000-1111-2222-3333-444444444444",

          "sample_tubes": {
            "actions": {
              "read": "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444/sample_tubes"
            }
          }
        },
        "uuids_to_ids": {
          "00000000-1111-2222-3333-444444444444": 1
        }
      }
      """
