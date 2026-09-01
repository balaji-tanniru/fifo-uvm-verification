# FIFO Verification Plan

| Feature | Test | Expected result |
|---|---|---|
| Reset | Assert reset for three clocks | Empty=1, full=0, count=0 |
| Fill | Write DEPTH values | Full=1 and ordered storage |
| Overflow | Write while full | Count and contents stay unchanged |
| Drain | Read all values | Data order matches reference queue |
| Underflow | Read while empty | Count stays zero |
| Simultaneous access | Read and write together | Count stays constant; ordering preserved |
| Random regression | 40 mixed operations | Zero scoreboard errors |

Proof files are created in `proof/`: test log, VCD waveform, UVM log and coverage report.
