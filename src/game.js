const canvas = document.getElementById("game");
const ctx = canvas.getContext("2d");
const scoreText = document.getElementById("score");
const projectileText = document.getElementById("projectiles");
const statusText = document.getElementById("status");

const GRAVITY = 850;
const FRICTION = 0.99;
const REST_THRESHOLD = 16;
const MAX_DRAG = 120;
const LAUNCH_POWER = 4.2;

class CircleBody {
  constructor(x, y, radius, color, type) {
    this.x = x;
    this.y = y;
    this.vx = 0;
    this.vy = 0;
    this.radius = radius;
    this.color = color;
    this.type = type;
    this.alive = true;
    this.dynamic = true;
  }

  draw() {
    ctx.fillStyle = this.color;
    ctx.beginPath();
    ctx.arc(this.x, this.y, this.radius, 0, Math.PI * 2);
    ctx.fill();
  }
}

class RectBody {
  constructor(x, y, w, h, color, dynamic = false) {
    this.x = x;
    this.y = y;
    this.w = w;
    this.h = h;
    this.vx = 0;
    this.vy = 0;
    this.color = color;
    this.alive = true;
    this.dynamic = dynamic;
  }

  draw() {
    ctx.fillStyle = this.color;
    ctx.fillRect(this.x, this.y, this.w, this.h);
  }
}

class Game {
  constructor() {
    this.groundY = canvas.height - 30;
    this.anchor = { x: 150, y: this.groundY - 30 };
    this.score = 0;
    this.state = "aiming";
    this.dragging = false;
    this.projectileIndex = 0;
    this.projectiles = [];
    this.enemies = [];
    this.blocks = [];
    this.pendingProjectile = null;
    this.lastFrame = performance.now();

    this.bindInput();
    this.setupLevel();
    requestAnimationFrame((t) => this.loop(t));
  }

  setupLevel() {
    this.blocks = [
      new RectBody(640, this.groundY - 20, 180, 20, "#7c3aed"),
      new RectBody(670, this.groundY - 70, 30, 50, "#a78bfa", true),
      new RectBody(760, this.groundY - 70, 30, 50, "#a78bfa", true),
      new RectBody(700, this.groundY - 120, 90, 20, "#8b5cf6", true),
    ];

    this.enemies = [
      new CircleBody(715, this.groundY - 135, 16, "#ef4444", "enemy"),
      new CircleBody(745, this.groundY - 135, 16, "#f97316", "enemy"),
    ];

    this.projectiles = [
      new CircleBody(this.anchor.x, this.anchor.y, 14, "#22c55e", "projectile"),
      new CircleBody(this.anchor.x - 36, this.anchor.y + 8, 14, "#06b6d4", "projectile"),
      new CircleBody(this.anchor.x - 72, this.anchor.y + 14, 14, "#eab308", "projectile"),
    ];

    this.currentProjectile().x = this.anchor.x;
    this.currentProjectile().y = this.anchor.y;
    this.currentProjectile().dynamic = false;
    this.refreshHud();
  }

  currentProjectile() {
    return this.projectiles[this.projectileIndex];
  }

  bindInput() {
    const start = (evt) => {
      if (this.state !== "aiming") return;
      const p = this.currentProjectile();
      if (!p || !p.alive) return;

      const point = this.getPointer(evt);
      const dist = Math.hypot(point.x - p.x, point.y - p.y);
      if (dist <= p.radius + 20) {
        this.dragging = true;
      }
    };

    const move = (evt) => {
      if (!this.dragging) return;
      const point = this.getPointer(evt);
      const dx = point.x - this.anchor.x;
      const dy = point.y - this.anchor.y;
      const dist = Math.hypot(dx, dy);
      const clamped = Math.min(dist, MAX_DRAG);
      const angle = Math.atan2(dy, dx);

      const p = this.currentProjectile();
      p.x = this.anchor.x + Math.cos(angle) * clamped;
      p.y = this.anchor.y + Math.sin(angle) * clamped;
    };

    const end = () => {
      if (!this.dragging || this.state !== "aiming") return;
      this.dragging = false;
      this.launchCurrentProjectile();
    };

    canvas.addEventListener("pointerdown", start);
    canvas.addEventListener("pointermove", move);
    window.addEventListener("pointerup", end);
    window.addEventListener("pointercancel", end);
  }

  getPointer(evt) {
    const rect = canvas.getBoundingClientRect();
    const scaleX = canvas.width / rect.width;
    const scaleY = canvas.height / rect.height;
    return {
      x: (evt.clientX - rect.left) * scaleX,
      y: (evt.clientY - rect.top) * scaleY,
    };
  }

  launchCurrentProjectile() {
    const p = this.currentProjectile();
    if (!p) return;

    const dx = this.anchor.x - p.x;
    const dy = this.anchor.y - p.y;
    p.vx = dx * LAUNCH_POWER;
    p.vy = dy * LAUNCH_POWER;
    p.dynamic = true;
    this.state = "launched";
    statusText.textContent = "Status: Projectile in flight";
  }

  queueNextProjectile() {
    this.projectileIndex += 1;
    if (this.projectileIndex >= this.projectiles.length) {
      return;
    }

    const p = this.currentProjectile();
    p.x = this.anchor.x;
    p.y = this.anchor.y;
    p.vx = 0;
    p.vy = 0;
    p.dynamic = false;
    this.state = "aiming";
    statusText.textContent = "Status: Aim and fling!";
    this.refreshHud();
  }

  updateDynamicCircle(body, dt) {
    if (!body.dynamic || !body.alive) return;

    body.vy += GRAVITY * dt;
    body.x += body.vx * dt;
    body.y += body.vy * dt;

    body.vx *= FRICTION;
    body.vy *= FRICTION;

    if (body.y + body.radius > this.groundY) {
      body.y = this.groundY - body.radius;
      body.vy *= -0.45;
      body.vx *= 0.9;
    }

    if (body.x - body.radius < 0) {
      body.x = body.radius;
      body.vx *= -0.4;
    }

    if (body.x + body.radius > canvas.width) {
      body.x = canvas.width - body.radius;
      body.vx *= -0.4;
    }
  }

  updateDynamicRect(block, dt) {
    if (!block.dynamic || !block.alive) return;

    block.vy += GRAVITY * dt;
    block.x += block.vx * dt;
    block.y += block.vy * dt;
    block.vx *= 0.985;
    block.vy *= 0.985;

    if (block.y + block.h > this.groundY) {
      block.y = this.groundY - block.h;
      block.vy *= -0.25;
    }
  }

  handleCircleRectCollision(circle, rect) {
    if (!circle.alive || !rect.alive) return;

    const nearestX = Math.max(rect.x, Math.min(circle.x, rect.x + rect.w));
    const nearestY = Math.max(rect.y, Math.min(circle.y, rect.y + rect.h));
    const dx = circle.x - nearestX;
    const dy = circle.y - nearestY;
    const d2 = dx * dx + dy * dy;

    if (d2 <= circle.radius * circle.radius) {
      const speed = Math.hypot(circle.vx, circle.vy);
      const nx = dx || 0.001;
      const ny = dy || 0.001;
      const normal = Math.hypot(nx, ny);
      circle.vx += (nx / normal) * 50;
      circle.vy += (ny / normal) * 50;
      circle.vx *= -0.35;
      circle.vy *= -0.35;

      if (rect.dynamic) {
        rect.vx += circle.vx * 0.4;
        rect.vy += circle.vy * 0.3;
      }

      if (speed > 240 && rect.dynamic) {
        rect.alive = false;
        this.score += 50;
      }
    }
  }

  handleCircleCircleCollision(a, b) {
    if (!a.alive || !b.alive) return;

    const dx = b.x - a.x;
    const dy = b.y - a.y;
    const dist = Math.hypot(dx, dy);
    const minDist = a.radius + b.radius;

    if (dist < minDist) {
      const nx = dx / (dist || 1);
      const ny = dy / (dist || 1);
      const relVel = (a.vx - b.vx) * nx + (a.vy - b.vy) * ny;

      a.vx -= relVel * nx * 0.8;
      a.vy -= relVel * ny * 0.8;
      b.vx += relVel * nx * 0.7;
      b.vy += relVel * ny * 0.7;

      if (a.type === "projectile" && b.type === "enemy" && Math.hypot(a.vx, a.vy) > 170) {
        b.alive = false;
        this.score += 250;
      }
    }
  }

  checkGameState() {
    const activeEnemies = this.enemies.filter((e) => e.alive).length;
    if (activeEnemies === 0) {
      this.state = "won";
      statusText.textContent = "Status: You win!";
      return;
    }

    const p = this.currentProjectile();
    if (this.state === "launched" && p) {
      const speed = Math.hypot(p.vx, p.vy);
      const resting = speed < REST_THRESHOLD && p.y >= this.groundY - p.radius - 1;
      const outOfPlay = p.x > canvas.width + 100 || p.x < -100 || p.y > canvas.height + 140;

      if (resting || outOfPlay) {
        this.queueNextProjectile();
      }
    }

    if (this.projectileIndex >= this.projectiles.length && this.state !== "won") {
      this.state = "lost";
      statusText.textContent = "Status: Out of projectiles - you lose";
    }
  }

  refreshHud() {
    scoreText.textContent = `Score: ${this.score}`;
    projectileText.textContent = `Projectiles: ${Math.max(0, this.projectiles.length - this.projectileIndex)}`;
  }

  update(dt) {
    if (this.state === "won" || this.state === "lost") return;

    for (const projectile of this.projectiles) {
      this.updateDynamicCircle(projectile, dt);
    }

    for (const enemy of this.enemies) {
      this.updateDynamicCircle(enemy, dt);
      for (const block of this.blocks) {
        this.handleCircleRectCollision(enemy, block);
      }
    }

    for (const block of this.blocks) {
      this.updateDynamicRect(block, dt);
    }

    for (const projectile of this.projectiles) {
      if (!projectile.dynamic || !projectile.alive) continue;
      for (const block of this.blocks) {
        this.handleCircleRectCollision(projectile, block);
      }

      for (const enemy of this.enemies) {
        this.handleCircleCircleCollision(projectile, enemy);
      }
    }

    this.checkGameState();
    this.refreshHud();
  }

  drawSlingshot() {
    const p = this.currentProjectile();
    const attachX = p && this.state === "aiming" ? p.x : this.anchor.x;
    const attachY = p && this.state === "aiming" ? p.y : this.anchor.y;

    ctx.strokeStyle = "#78350f";
    ctx.lineWidth = 8;
    ctx.beginPath();
    ctx.moveTo(this.anchor.x - 20, this.anchor.y + 22);
    ctx.lineTo(this.anchor.x, this.anchor.y - 40);
    ctx.lineTo(this.anchor.x + 20, this.anchor.y + 22);
    ctx.stroke();

    ctx.strokeStyle = "#fbbf24";
    ctx.lineWidth = 3;
    ctx.beginPath();
    ctx.moveTo(this.anchor.x - 16, this.anchor.y - 10);
    ctx.lineTo(attachX, attachY);
    ctx.lineTo(this.anchor.x + 16, this.anchor.y - 10);
    ctx.stroke();
  }

  render() {
    ctx.clearRect(0, 0, canvas.width, canvas.height);

    ctx.fillStyle = "#166534";
    ctx.fillRect(0, this.groundY, canvas.width, canvas.height - this.groundY);

    this.drawSlingshot();

    for (const block of this.blocks) {
      if (block.alive) block.draw();
    }

    for (const enemy of this.enemies) {
      if (enemy.alive) enemy.draw();
    }

    this.projectiles.forEach((projectile, i) => {
      if (!projectile.alive) return;
      if (i < this.projectileIndex) {
        projectile.color = "#64748b";
      }
      projectile.draw();
    });
  }

  loop(now) {
    const dt = Math.min((now - this.lastFrame) / 1000, 1 / 30);
    this.lastFrame = now;

    this.update(dt);
    this.render();
    requestAnimationFrame((t) => this.loop(t));
  }
}

new Game();
