Every week you'll work through a Jupyter notebook, e.g. `CNU_Week3.ipynb`. You run them online on **JupyterHub.nrw**, so you don't need to install anything on your own computer. The images and data come from the course **Sciebo** folder; the notebooks come from the course **GitHub** repository.

---

## Before the first session

**Make sure you have access to the course Sciebo folder.**

You should have received a share invitation for the folder `CNU`. Log in to Sciebo in your browser and check that `CNU` shows up in your files. If it's listed as a pending share, accept it first. If you don't see it at all, please let me know. 

---

## 1. Start your JupyterHub server

1. Go to https://www.jupyterhub.nrw/en/ and choose **University of Münster** (or go straight to https://uni-muenster.jupyterhub.nrw).
2. Log in with your university account.
3. On the start page, select these options:
   - **CPU:** 1.0 – 8.0 vCPU
   - **Memory:** 4 GiB – 8 GiB
   - **Image:** Data Science + Machine Learning
     - Python, R, CUDA, PyTorch, TensorFlow → **latest version**
4. **Connect your Sciebo account** on the same page and allow access when Sciebo asks.
5. Start the server. The first start can take a minute or two.

When JupyterLab opens, you should see a folder called `sciebo` in the file browser on the left. Inside it is `CNU`, with one subfolder per week (`Week2`, `Week3`, …).

---

## 2. Get the notebooks 

In JupyterLab, open **File → New → Terminal** and run:

```bash
git clone https://github.com/ekin-doga/Cognitive_Neuroscience_Update.git
```

This creates a folder `Cognitive_Neuroscience_Update` with one folder per week, e.g. `Week3-Lindsay2021/CNU_Week3.ipynb`.

You only do this **once**. Don't run `git clone` again. It would fail, because the folder already exists.

**Before each session, get the latest version** by running this in a terminal:

```bash
cd ~/Cognitive_Neuroscience_Update
git pull
```

This downloads new weeks and any changes to earlier notebooks. The notebooks may be updated during the semester (fixes, new exercises), so pull every time.

`git pull` only updates the notebooks. 

Note: If you want to keep a copy of the notebook you should download it. 

---
## 3. Run the first notebook

1. Go here in the folder tree: /Cognitive_Neuroscience_Update/Week2-Intro-AlexNet/
2. Click on CNU_Week2.ipynb
3. Click on the run (marked with red rectangle) and see whether everything runs without an error
