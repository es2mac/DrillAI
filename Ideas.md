
## Possible next steps

- Bug: Line clear explosion no longer animates
    - Why?  Does the original setting both play piece and field at the same time
      help, and separating them breaks animation somehow?
        - Try combining them in enqueue
        - Try longer animation time
        - Maybe as well extract constants to static vars
    - Write up implementation note
        - Suspecting performance: longer animation time works, but not setting same time
        - Lowering queue qos actually helps a little... but that's weird for UI updates
        - Suspecting thread sleep, but that's still not it
        - Maybe it's not the operation queue's fault, but dispatch to main?

- Twist and slide moves
    - Implement SRS wallkicks
    - "Hinge" detection as a fast first-screen
        Check for 2x2 shape with only top left or right filled
        ```
        O _          _ O
        _ _    or    _ _
        ```
    - Only check from natural drop positions, and not hanging in midair
        - Searching from existing list of moves has a flaw, that is the S/Z/I
          pieces don't have separate L/R rotations for same positions
        - Graph search with natural drops as starting points, use the working
          array with pointer like a queue, plus a Set

- Bot play/pause button
    - SFSymbols & tint

- Record game in-memory and long-term
    - Add controls, e.g. replay history
    - Two seeds, history of move pieces
        - These are enough to programmatically recreate the game
    - Optionally, available piece sequence, clear counts, fields

- Fix all the SwiftUI previews, in due time

- Placing piece sequence
    - Generate the move sequence from spawn to final position
        - This may be very similar to finding all moves
            - Unless I search backwards... more efficient

- Animated hard drop flash
   

- More concrete types for where I'm using tuples to pass information around
    - Rethink the treatment of typealias ActionVisits
    

