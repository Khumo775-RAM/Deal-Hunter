import asyncio
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from routes import auth, deals, games, search, tracking  # noqa: F401
from services.notification_service import check_and_notify

# How often the background loop re-checks prices (6 hours).
PRICE_CHECK_INTERVAL_SECONDS = 6 * 3600


async def notification_loop():
    """
    Background task — Option B:
      1. Check immediately on startup so missed deals are caught right away.
      2. Then repeat every PRICE_CHECK_INTERVAL_SECONDS.
    """
    # Small delay so the app is fully started before the first network calls.
    await asyncio.sleep(3)
    await check_and_notify()

    while True:
        await asyncio.sleep(PRICE_CHECK_INTERVAL_SECONDS)
        await check_and_notify()


@asynccontextmanager
async def lifespan(app: FastAPI):
    task = asyncio.create_task(notification_loop())
    yield
    task.cancel()
    try:
        await task
    except asyncio.CancelledError:
        pass


app = FastAPI(
    title="Game Deal Tracker API",
    description="Track game deals in real time using the CheapShark API.",
    version="1.0.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router)
app.include_router(deals.router)
app.include_router(games.router)
app.include_router(search.router)
app.include_router(tracking.router)


@app.get("/", tags=["Health"])
def root():
    return {"status": "ok", "message": "Game Deal Tracker API is running"}
