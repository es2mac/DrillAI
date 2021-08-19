
## Possible next steps

- Record game in-memory and long-term
    - Add controls, e.g. replay history
    - Two seeds, history of move pieces
        - These are enough to programmatically recreate the game
    - Optionally, available piece sequence, clear counts, fields
        - See old constructFeaturePlanes for what to store
        - Also ref. ML steps below

- Improved DisplayField rows & drawing strategy (cf. wish list)

- Placing piece sequence
    - Generate the move sequence from spawn to final position
        - This may be very similar to finding all moves
            - Unless I search backwards... more efficient

- Animated hard drop flash
   
- Fix all the SwiftUI previews, in due time

- More concrete types for where I'm using tuples to pass information around
    - Rethink the treatment of typealias ActionVisits
    
- Consider the issue of limited search depth
    - Or not?

- ML steps
    - Swift: play and log game to storage
        - Game minimal log: 2 random seeds, sequence of all actions
        - Tree log: for each step, array of actions (pieces) and array of Ns
    - Swift: prep training data, for each step
        - Input:
            - Field: 200 booleans
            - Pieces: 2~6 tetromino raw values
        - Output:
            - Prior: convert action to index in the 10x20x8 (0~1600)
                     convert Ns to %s
            - Value: number of garbages cleared by this & 13 more steps
        - Save as Protobuf?  One file per game.
    - Transfer files from app storage to training-accessible storage
        - Maybe implement simple file browser and AirDrop
        - Maybe Google Drive -> Colab
    - Python: read and convert data to model input and labels
        - Input: dim = (10, 20, 43) of 1-bits (8600)
            - 0: actual field
            - 1-14: two available play pieces
            - 15-42: up to 4 more previews (uses up all info if no hold)
        - Output:
            - Prior: dim = (10, 20, 4x2) of floats (1600)
            - Value: a double
        - Augmentation: reduced previews down to using the two play pieces
    - Python: train and export coreml model
    - Swift: load coreml model
    - Swift: convert current state to model input

- Twist and slide moves
    - Profile the performance impact (it's very heavy.)
    - Revisit logic to see how to improve the code and efficiency


