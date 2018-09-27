# retinopathy
Experimental code for a similarity-judgement retinopathy task.

Project Description

The goal of this project is to develop a training paradigm for the diagnosis of diabetic retinopathy via retina images. Retinopathy is currently diagnosed on a severity scale, ranging from 0 (no retinopathy) to 4 (proliferative retinopathy). Research suggests that diagnosing retinopathy is challenging for doctors, as evidenced by low confidence ratings by early-career physicians. Pilot data suggests that traditional trial-and-error learning may not be effective here; instead, we will combine feedback learning with implicit categorization (specifically, similarity judgements). 

In a similarity judgement task, participants are asked to select, from among several reference images, the image that most resembles a target image. A successful implicit categorization is said to have occurred if the selected reference image and the target image share the same category (or diagnosis, in this case). Here, participants will be shown a centrally-presented target retina, surrounded by ten reference retinas (two from each category, 0-4). 

Participants will be first instructed on retinopathy in general, and on the relevant features of retinopathy in particular (e.g. hard exudates and hemorrhaging). Participants will then be told the structure of the task and that similarity judgements should be made on the perceived severity of the retinopathy. Participants will be unaware that there are five levels of severity. Furthermore (and novelly compared to previous similarity judgement tasks) feedback will be provided after each similarity judgement - a checkmark if the selected reference image is of the same category as the target image, or an x otherwise.

From these data we hope to address: 1. how retina images are represented perceptually (and what this might mean for the difficulty of making a diagnosis), and 2. whether feedback-based learning is possible in a similarity judgement task. Once we have embedded our stimuli in “perceptual space”, we may then (in a future study) attempt to optimize our training paradigm through reference-image selection. (Prior research suggests that similarity judgements can be improved by picking certain reference images.)

DVs
- response time for each selection
- triplets ABC (generated with every selection) of the form A is more similar to B than C
- EEG during selection, and in response to feedback

Markers

255 - Start of trial
1 - 10 Response
11 - 20 Incorrect
21 - 30 Correct

Behavioural File Columns

1. block number
2. round number (1 block = 25 rounds)
3. response/trial number
4. image index (counts up from 1, redundant with column 2)
5. image number (row number in checkedimages.csv)
6. query image label (0: none, 1: mild, 2: moderate, 3: severe, 4: proliferative)
7. chosen reference image label (0: none, 1: mild, 2: moderate, 3: severe, 4: proliferative)
8. accuracy (1: correct, 0: incorrect)
9. response time (in seconds)


