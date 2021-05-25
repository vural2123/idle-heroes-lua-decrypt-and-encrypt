local trial = {}

function trial.init(data)
    trial.stage = data.id
    trial.tl = data.tl
    if data.cd then
        trial.cd = data.cd + os.time()
    else
        trial.cd = os.time() + 1800
    end
end

function trial.win()
    trial.stage = trial.stage + 1
end

function trial.lose()
    trial.tl = trial.tl - 1
    if trial.tl == 9 then
        trial.cd = os.time() + 1800
    end
end

function trial.initVideo(videos)
    trial.videos = videos
    trial.video_stage = trial.stage
end

return trial
