import React, { useEffect, useMemo, useState } from "react";

const DEFAULT_SECONDS = 3613;
const SHORT_SECONDS = 913;
const MAX_SECONDS = 7200;

const INITIAL_MUSHROOMS = [
  { id: "m1", location: "功夫壁畫", type: "一般 輝煌蘑菇", seconds: 3613, finish: "09:15", refresh: "09:20" },
  { id: "m2", location: "森林入口", type: "巨大 紅蘑菇", seconds: 913, finish: "08:30", refresh: "08:35" },
  { id: "m3", location: "車站廣場", type: "水晶蘑菇", seconds: 7420, finish: "10:18", refresh: "10:23" }
];

const NOTIFY_STEPS = [
  { label: "蘑菇結束", offset: "T + 0:00", tone: "任務完成，準備刷新" },
  { label: "倒數 2 分鐘", offset: "T + 3:00", tone: "新蘑菇快出現" },
  { label: "倒數 1 分鐘", offset: "T + 4:00", tone: "準備打開 Pikmin" },
  { label: "倒數 30 秒", offset: "T + 4:30", tone: "提醒變頻繁" },
  { label: "倒數 10 秒", offset: "T + 4:50", tone: "最後提醒" },
  { label: "刷新時間", offset: "T + 5:00", tone: "新蘑菇可能出現了" }
];

function clamp(value, min, max) {
  return Math.min(Math.max(value, min), max);
}

function twoDigits(value) {
  const safeValue = Math.max(0, Math.floor(Number(value) || 0));
  return safeValue < 10 ? "0" + safeValue : String(safeValue);
}

function formatTime(totalSeconds) {
  const safeSeconds = Math.max(0, Math.floor(Number(totalSeconds) || 0));
  const hours = Math.floor(safeSeconds / 3600);
  const minutes = Math.floor((safeSeconds % 3600) / 60);
  const seconds = safeSeconds % 60;
  return twoDigits(hours) + ":" + twoDigits(minutes) + ":" + twoDigits(seconds);
}

function parseRemainingTime(text) {
  const match = String(text).match(/剩下\s*(\d+)\s*小時\s*(\d+)\s*分\s*(\d+)\s*秒/);
  if (!match) return null;
  return Number(match[1]) * 3600 + Number(match[2]) * 60 + Number(match[3]);
}

function getProgress(seconds, maxSeconds) {
  const base = Number(maxSeconds) || MAX_SECONDS;
  return clamp(1 - Number(seconds) / base, 0, 1);
}

function getSchedule(seconds) {
  if (seconds === SHORT_SECONDS) return { finish: "08:30", refresh: "08:35" };
  return { finish: "09:15", refresh: "09:20" };
}

function cloneMushrooms() {
  return INITIAL_MUSHROOMS.map((item) => ({ ...item }));
}

function getNextActiveId(list, deletedId, currentActiveId) {
  if (currentActiveId !== deletedId) return currentActiveId;
  return list.length > 0 ? list[0].id : "";
}

function runSelfTests() {
  console.assert(twoDigits(0) === "00", "twoDigits formats zero");
  console.assert(twoDigits(9) === "09", "twoDigits formats one digit");
  console.assert(twoDigits(12) === "12", "twoDigits keeps two digits");
  console.assert(formatTime(0) === "00:00:00", "formatTime formats zero seconds");
  console.assert(formatTime(DEFAULT_SECONDS) === "01:00:13", "formatTime formats default seconds");
  console.assert(formatTime(-10) === "00:00:00", "formatTime clamps negative seconds");
  console.assert(parseRemainingTime("剩下 1 小時 0 分 13 秒") === 3613, "parseRemainingTime parses normal OCR text");
  console.assert(parseRemainingTime("剩下1小時0分13秒") === 3613, "parseRemainingTime parses compact OCR text");
  console.assert(parseRemainingTime("沒有時間") === null, "parseRemainingTime returns null for invalid text");
  console.assert(getProgress(0, MAX_SECONDS) === 1, "getProgress is full at zero seconds");
  console.assert(getProgress(MAX_SECONDS, MAX_SECONDS) === 0, "getProgress is empty at max seconds");
  console.assert(getSchedule(SHORT_SECONDS).refresh === "08:35", "getSchedule uses short demo refresh time");
  console.assert(cloneMushrooms() !== INITIAL_MUSHROOMS, "cloneMushrooms returns a new array");
  console.assert(cloneMushrooms()[0] !== INITIAL_MUSHROOMS[0], "cloneMushrooms returns new objects");
  console.assert(getNextActiveId([{ id: "b" }], "a", "a") === "b", "getNextActiveId switches after deleting active item");
  console.assert(getNextActiveId([], "a", "a") === "", "getNextActiveId handles empty list");
}

runSelfTests();

function Icon({ name, className = "" }) {
  const icons = {
    bell: "🔔",
    camera: "📷",
    clock: "🕒",
    image: "🖼️",
    mushroom: "🍄",
    plus: "+",
    sparkles: "✨",
    timer: "⏱️",
    location: "📍",
    trash: "🗑️"
  };
  return <span aria-hidden="true" className={"inline-flex items-center justify-center " + className}>{icons[name] || "•"}</span>;
}

function Panel({ children, className = "" }) {
  return <div className={"rounded-3xl border-0 bg-white/90 shadow-lg " + className}>{children}</div>;
}

function PrimaryButton({ children, onClick, className = "" }) {
  return (
    <button type="button" onClick={onClick} className={"inline-flex items-center justify-center rounded-2xl bg-emerald-500 px-4 font-bold text-white shadow-lg transition hover:bg-emerald-600 " + className}>
      {children}
    </button>
  );
}

function OutlineButton({ children, onClick }) {
  return (
    <button type="button" onClick={onClick} className="h-12 rounded-2xl border border-slate-200 bg-white px-4 font-semibold transition hover:bg-slate-50">
      {children}
    </button>
  );
}

function ReminderRow({ item, index }) {
  return (
    <div className="flex items-center gap-3 rounded-2xl bg-white/80 p-3 shadow-sm">
      <div className="flex h-9 w-9 items-center justify-center rounded-xl bg-emerald-100 text-sm font-black">{index + 1}</div>
      <div className="flex-1">
        <p className="text-sm font-bold">{item.label}</p>
        <p className="text-xs text-slate-500">{item.offset} · {item.tone}</p>
      </div>
    </div>
  );
}

function HeroCard({ mushroom }) {
  const progressDegrees = Math.round(getProgress(mushroom.seconds, MAX_SECONDS) * 360);
  const ringStyle = { background: "conic-gradient(#22c55e " + progressDegrees + "deg, #d1fae5 0deg)" };

  return (
    <div className="relative overflow-hidden rounded-3xl bg-white/90 p-6 text-slate-900 shadow-xl backdrop-blur">
      <div className="absolute -right-6 -top-6 h-32 w-32 rounded-full bg-emerald-200/50 blur-2xl" />
      <div className="absolute bottom-0 right-0 h-40 w-40 rounded-full bg-lime-200/60 blur-3xl" />
      <div className="relative flex items-start justify-between gap-3">
        <div>
          <p className="text-sm font-bold text-slate-500">{mushroom.type}</p>
          <h2 className="mt-1 text-2xl font-black tracking-tight">{mushroom.location}</h2>
          <div className="mt-3 inline-flex items-center gap-2 rounded-full bg-emerald-50 px-3 py-1 text-xs font-bold text-emerald-700">
            <Icon name="location" /> Pikmin Bloom Mushroom
          </div>
        </div>
        <div className="rounded-2xl bg-emerald-50 p-3">
          <Icon name="mushroom" className="text-2xl" />
        </div>
      </div>
      <div className="relative mx-auto mt-8 flex h-56 w-56 items-center justify-center rounded-full bg-emerald-50">
        <div className="absolute inset-0 rounded-full" style={ringStyle} />
        <div className="absolute inset-4 rounded-full bg-white shadow-inner" />
        <div className="relative text-center">
          <p className="text-xs font-bold text-slate-500">剩下時間</p>
          <p className="text-5xl font-black tracking-tight tabular-nums">{formatTime(mushroom.seconds)}</p>
          <p className="mt-2 text-xs font-bold text-lime-600">新蘑菇刷新提醒模式</p>
        </div>
      </div>
      <div className="mt-6 grid grid-cols-2 gap-3">
        <div className="rounded-2xl bg-slate-50 p-4">
          <p className="text-xs text-slate-500">結束時間</p>
          <p className="mt-1 text-lg font-black">{mushroom.finish}</p>
        </div>
        <div className="rounded-2xl bg-slate-50 p-4">
          <p className="text-xs text-slate-500">刷新時間</p>
          <p className="mt-1 text-lg font-black text-emerald-700">{mushroom.refresh}</p>
        </div>
      </div>
    </div>
  );
}

function MushroomCard({ mushroom, activeId, onSelect, onRequestDelete }) {
  const isActive = activeId === mushroom.id;
  const activeClass = isActive ? "bg-emerald-100 ring-2 ring-emerald-400 " : "bg-white ";

  return (
    <div className={activeClass + "relative w-60 shrink-0 rounded-3xl p-4 text-left shadow-sm transition hover:bg-emerald-50"}>
      <button type="button" onClick={() => onRequestDelete(mushroom.id)} className="absolute right-3 top-3 z-10 flex h-8 w-8 items-center justify-center rounded-full bg-slate-100 text-sm font-black text-slate-500 transition hover:bg-rose-100 hover:text-rose-600" aria-label={"刪除 " + mushroom.location}>
        ×
      </button>
      <button type="button" onClick={() => onSelect(mushroom.id)} className="w-full text-left">
        <div className="flex items-center gap-3 pr-8">
          <div className="flex h-12 w-12 items-center justify-center rounded-2xl bg-emerald-50 text-2xl">🍄</div>
          <div className="min-w-0 flex-1">
            <p className="truncate text-sm font-black">{mushroom.location}</p>
            <p className="truncate text-xs text-slate-500">{mushroom.type}</p>
          </div>
        </div>
        <p className="mt-4 text-2xl font-black tabular-nums">{formatTime(mushroom.seconds)}</p>
        <div className="mt-2 flex items-center justify-between text-xs text-slate-500">
          <span>結束 {mushroom.finish}</span>
          <span className="font-bold text-emerald-700">刷新 {mushroom.refresh}</span>
        </div>
      </button>
    </div>
  );
}

function EmptyState({ onOpenAdd }) {
  return (
    <div className="mt-6 space-y-5">
      <Panel>
        <div className="p-8 text-center">
          <div className="mx-auto flex h-20 w-20 items-center justify-center rounded-3xl bg-emerald-50 text-4xl">🍄</div>
          <h2 className="mt-5 text-2xl font-black">目前沒有鬧鐘</h2>
          <p className="mt-2 text-sm text-slate-500">新增 Pikmin 截圖後，會自動建立蘑菇倒數與刷新提醒。</p>
          <PrimaryButton onClick={onOpenAdd} className="mt-6 h-14 w-full text-base">
            <Icon name="plus" className="mr-2 text-xl" /> 新增蘑菇鬧鐘
          </PrimaryButton>
        </div>
      </Panel>
    </div>
  );
}

function HomeScreen({ mushrooms, activeId, onSelect, onOpenAdd, onRequestDelete }) {
  const selected = mushrooms.find((item) => item.id === activeId) || mushrooms[0];
  if (!selected) return <EmptyState onOpenAdd={onOpenAdd} />;

  return (
    <div className="mt-6 space-y-5">
      <HeroCard mushroom={selected} />
      <div className="-mx-1 overflow-x-auto pb-2">
        <div className="flex gap-3 px-1">
          {mushrooms.map((item) => (
            <MushroomCard key={item.id} mushroom={item} activeId={activeId} onSelect={onSelect} onRequestDelete={onRequestDelete} />
          ))}
        </div>
      </div>
      <div className="flex items-center justify-center gap-2">
        {mushrooms.map((item) => {
          const dotClass = activeId === item.id ? "w-8 bg-emerald-500 " : "w-2 bg-slate-300 ";
          return <button key={item.id} type="button" aria-label={"切換到 " + item.location} onClick={() => onSelect(item.id)} className={dotClass + "h-2 rounded-full transition-all"} />;
        })}
      </div>
      <PrimaryButton onClick={onOpenAdd} className="h-14 w-full text-base">
        <Icon name="plus" className="mr-2 text-xl" /> 新增蘑菇鬧鐘
      </PrimaryButton>
      <div className="space-y-3">
        <div className="flex items-center justify-between px-1">
          <p className="text-sm font-bold text-slate-600">刷新通知節奏</p>
          <p className="text-xs font-bold text-emerald-700">滑動切換蘑菇</p>
        </div>
        {NOTIFY_STEPS.slice(1, 5).map((item, index) => (
          <ReminderRow key={item.offset} item={item} index={index} />
        ))}
      </div>
    </div>
  );
}

function DeleteConfirmSheet({ mushroom, onCancel, onConfirm }) {
  if (!mushroom) return null;
  return (
    <div className="absolute inset-0 z-40 flex items-end bg-black/30 backdrop-blur-sm">
      <div className="w-full rounded-t-[2.5rem] bg-[#f8fbf4] p-5 shadow-2xl">
        <div className="mx-auto mb-4 h-1.5 w-16 rounded-full bg-slate-300" />
        <div className="text-center">
          <div className="mx-auto flex h-16 w-16 items-center justify-center rounded-3xl bg-rose-50 text-3xl">🗑️</div>
          <h2 className="mt-4 text-xl font-black">刪除這個鬧鐘？</h2>
          <p className="mt-2 text-sm text-slate-500">{mushroom.location} 的倒數與後續通知都會被移除。</p>
        </div>
        <div className="mt-6 grid gap-3">
          <button type="button" onClick={onConfirm} className="h-14 rounded-2xl bg-rose-500 font-black text-white shadow-lg transition hover:bg-rose-600">
            刪除鬧鐘
          </button>
          <button type="button" onClick={onCancel} className="h-14 rounded-2xl bg-white font-black text-slate-700 shadow-sm transition hover:bg-slate-50">
            取消
          </button>
        </div>
      </div>
    </div>
  );
}

function AddMushroomSheet({ onClose, onComplete }) {
  return (
    <div className="absolute inset-0 z-30 flex items-end bg-black/30 backdrop-blur-sm">
      <div className="w-full rounded-t-[2.5rem] bg-[#f8fbf4] p-5 shadow-2xl">
        <div className="mx-auto mb-4 h-1.5 w-16 rounded-full bg-slate-300" />
        <div className="flex items-center justify-between">
          <button type="button" onClick={onClose} className="text-base font-bold text-slate-500">取消</button>
          <h2 className="text-lg font-black">新增蘑菇</h2>
          <button type="button" onClick={onComplete} className="text-base font-black text-emerald-600">完成</button>
        </div>
        <div className="mt-5 rounded-3xl border-2 border-dashed border-emerald-300 bg-emerald-50 p-8 text-center">
          <Icon name="image" className="mx-auto h-12 w-12 text-4xl" />
          <p className="mt-3 text-lg font-black">選擇 Pikmin 截圖</p>
          <p className="mt-1 text-sm text-slate-500">可一次選多張，自動建立蘑菇鬧鐘</p>
        </div>
        <div className="mt-5 space-y-3">
          {INITIAL_MUSHROOMS.slice(0, 2).map((item) => (
            <div key={item.id} className="rounded-2xl bg-white p-4 shadow-sm">
              <div className="flex items-center justify-between">
                <div>
                  <p className="font-black">{item.location}</p>
                  <p className="text-sm text-slate-500">{item.type}</p>
                </div>
                <p className="text-lg font-black">{formatTime(item.seconds)}</p>
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}

export default function PikminAlarmMockup() {
  const [isAdding, setIsAdding] = useState(false);
  const [deleteTargetId, setDeleteTargetId] = useState("");
  const [activeId, setActiveId] = useState(INITIAL_MUSHROOMS[0].id);
  const [mushrooms, setMushrooms] = useState(() => cloneMushrooms());
  const [isRunning, setIsRunning] = useState(true);

  useEffect(() => {
    if (!isRunning) return undefined;
    const timer = window.setInterval(() => {
      setMushrooms((previous) => previous.map((item) => ({ ...item, seconds: Math.max(0, item.seconds - 1) })));
    }, 1000);
    return () => window.clearInterval(timer);
  }, [isRunning]);

  const title = useMemo(() => (isAdding ? "新增蘑菇" : "蘑菇鬧鐘"), [isAdding]);
  const deleteTarget = mushrooms.find((item) => item.id === deleteTargetId) || null;

  function confirmDelete() {
    setMushrooms((previous) => {
      const next = previous.filter((item) => item.id !== deleteTargetId);
      setActiveId((current) => getNextActiveId(next, deleteTargetId, current));
      return next;
    });
    setDeleteTargetId("");
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-lime-100 via-emerald-100 to-sky-100 p-6 text-slate-900">
      <div className="mx-auto grid max-w-6xl gap-6 lg:grid-cols-[390px_1fr]">
        <div className="mx-auto w-[390px] rounded-[2.5rem] bg-slate-950 p-3 shadow-2xl">
          <div className="relative h-[800px] overflow-hidden rounded-[2rem] bg-[#f8fbf4]">
            <div className="absolute left-1/2 top-3 h-6 w-28 -translate-x-1/2 rounded-full bg-slate-950" />
            <div className="h-full overflow-y-auto p-6 pt-12">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm font-medium text-emerald-700">Pikmin Mushroom Alarm</p>
                  <h1 className="text-2xl font-black tracking-tight">{title}</h1>
                </div>
                {!isAdding && (
                  <button type="button" onClick={() => setIsAdding(true)} className="flex h-12 w-12 items-center justify-center rounded-2xl bg-emerald-500 text-2xl font-black text-white shadow-lg transition hover:bg-emerald-600" aria-label="新增蘑菇鬧鐘">
                    +
                  </button>
                )}
              </div>
              <HomeScreen mushrooms={mushrooms} activeId={activeId} onSelect={setActiveId} onOpenAdd={() => setIsAdding(true)} onRequestDelete={(id) => setDeleteTargetId(id)} />
            </div>
            {isAdding && <AddMushroomSheet onClose={() => setIsAdding(false)} onComplete={() => setIsAdding(false)} />}
            {deleteTarget && <DeleteConfirmSheet mushroom={deleteTarget} onCancel={() => setDeleteTargetId("")} onConfirm={confirmDelete} />}
          </div>
        </div>

        <div className="space-y-6">
          <Panel className="bg-white/80 backdrop-blur">
            <div className="p-8">
              <h2 className="text-3xl font-black tracking-tight">互動式 App 畫面概念</h2>
              <p className="mt-3 leading-7 text-slate-600">左邊是 iPhone mockup。首頁保留 Carousel，大卡片可透過下方橫向卡片與圓點切換；新增流程改成底部 Sheet，比切頁更像 iOS 原生體驗。</p>
              <div className="mt-6 grid gap-4 md:grid-cols-3">
                <div className="rounded-3xl bg-lime-50 p-5">
                  <p className="font-black">1. 截圖匯入</p>
                  <p className="mt-2 text-sm text-slate-600">可一次導入多張截圖，系統逐張辨識。</p>
                </div>
                <div className="rounded-3xl bg-emerald-50 p-5">
                  <p className="font-black">2. OCR 解析</p>
                  <p className="mt-2 text-sm text-slate-600">每張圖抓地點、蘑菇類型與剩餘時間。</p>
                </div>
                <div className="rounded-3xl bg-amber-50 p-5">
                  <p className="font-black">3. 密集通知</p>
                  <p className="mt-2 text-sm text-slate-600">每個蘑菇各自排一組通知，避免互相混淆。</p>
                </div>
              </div>
            </div>
          </Panel>

          <Panel className="bg-white/80 backdrop-blur">
            <div className="p-8">
              <h3 className="text-xl font-black">可操作項目</h3>
              <div className="mt-4 grid gap-3 md:grid-cols-2">
                <OutlineButton onClick={() => { setMushrooms(cloneMushrooms()); setActiveId(INITIAL_MUSHROOMS[0].id); setDeleteTargetId(""); }}>
                  重置範例資料
                </OutlineButton>
                <OutlineButton onClick={() => setIsRunning((previous) => !previous)}>
                  {isRunning ? "暫停倒數" : "恢復倒數"}
                </OutlineButton>
                <OutlineButton onClick={() => setIsAdding(true)}>打開新增面板</OutlineButton>
                <OutlineButton onClick={() => setIsAdding(false)}>關閉新增面板</OutlineButton>
              </div>
            </div>
          </Panel>
        </div>
      </div>
    </div>
  );
}
