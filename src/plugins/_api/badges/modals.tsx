/*
 * Vencord, a Discord client mod
 * Copyright (c) 2025 Vendicated and contributors
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import ErrorBoundary from "@components/ErrorBoundary";
import { Flex } from "@components/Flex";
import { Heading } from "@components/Heading";
import { Heart } from "@components/Heart";
import { Paragraph } from "@components/Paragraph";
import { DonateButton, TranslateButton } from "@components/settings";
import { Margins } from "@utils/margins";
import { Modal, openModal } from "@webpack/common";

export function VencordDonorModal() {
    openModal(props => (
        <ErrorBoundary noop onError={() => {
            props.onClose();
            VencordNative.native.openExternal("https://github.com/sponsors/Vendicated");
        }}>
            <Modal
                {...props}
                title={
                    <Heading
                        tag="h2"
                        style={{
                            width: "100%",
                            textAlign: "center",
                            margin: 0
                        }}
                    >
                        <Flex justifyContent="center" alignItems="center" gap="0.5em">
                            <Heart />
                            Vencord Donor
                        </Flex>
                    </Heading>
                }
            >
                <div>
                    <Flex>
                        <img
                            role="presentation"
                            src="https://cdn.discordapp.com/emojis/1026533070955872337.png"
                            alt=""
                            style={{ margin: "auto" }}
                        />

                        <img
                            role="presentation"
                            src="https://cdn.discordapp.com/emojis/1026533090627174460.png"
                            alt=""
                            style={{ margin: "auto" }}
                        />
                    </Flex>

                    <div style={{ padding: "1em" }}>
                        <Paragraph>
                            This Badge is a special perk for Vencord Donors
                        </Paragraph>

                        <Paragraph className={Margins.top20}>
                            Please consider supporting the development of Vencord by becoming a donor.
                        </Paragraph>
                    </div>
                </div>

                <div>
                    <Flex justifyContent="center" style={{ width: "100%" }}>
                        <DonateButton />
                    </Flex>
                </div>
            </Modal>
        </ErrorBoundary>
    ));
}

export function MallCordDonorModal() {
    openModal(props => (
        <ErrorBoundary noop onError={() => {
            props.onClose();
        }}>
            <Modal
                {...props}
                title={
                    <Heading
                        tag="h2"
                        style={{
                            width: "100%",
                            textAlign: "center",
                            margin: 0
                        }}
                    >
                        <Flex justifyContent="center" alignItems="center" gap="0.5em">
                            <Heart />
                            MallCord Supporter
                        </Flex>
                    </Heading>
                }
            >
                <div>
                    <Flex>
                        <img
                            role="presentation"
                            src="https://iili.io/CfG9TKb.gif"
                            alt=""
                            style={{
                                margin: "auto",
                                width: "96px",
                                height: "96px",
                                borderRadius: "50%"
                            }}
                        />
                    </Flex>

                    <div style={{ padding: "1em" }}>
                        <Paragraph>
                            This badge is a special perk for MallCord Supporters.
                        </Paragraph>

                        <Paragraph className={Margins.top20}>
                            Support MallCord on Ko-fi to unlock this badge and support development.
                        </Paragraph>
                    </div>
                </div>

                <div>
                    <Flex justifyContent="center" style={{ width: "100%" }}>
                        <DonateButton mallcord />
                    </Flex>
                </div>
            </Modal>
        </ErrorBoundary>
    ));
}

export function MallCordTranslatorModal() {
    openModal(props => (
        <ErrorBoundary noop onError={() => {
            props.onClose();
        }}>
            <Modal
                {...props}
                title={
                    <Heading
                        tag="h2"
                        style={{
                            width: "100%",
                            textAlign: "center",
                            margin: 0
                        }}
                    >
                        <Flex justifyContent="center" alignItems="center" gap="0.5em">
                            MallCord Translator
                        </Flex>
                    </Heading>
                }
            >
                <div>
                    <Flex>
                        <img
                            className="vc-translate-modal-icon"
                            role="presentation"
                            src="https://badge.equicord.org/translator.png"
                            alt=""
                        />
                    </Flex>

                    <div className="vc-translate-modal-paragraph">
                        <Paragraph>
                            Awarded to contributors who expand MallCord language support.
                        </Paragraph>
                    </div>
                </div>

                <div>
                    <Flex justifyContent="center" style={{ width: "100%" }}>
                        <TranslateButton />
                    </Flex>
                </div>
            </Modal>
        </ErrorBoundary>
    ));
}

export function MallCordFounderModal() {
    openModal(props => (
        <ErrorBoundary noop onError={() => {
            props.onClose();
        }}>
            <Modal
                {...props}
                title={
                    <Heading
                        tag="h2"
                        style={{
                            width: "100%",
                            textAlign: "center",
                            margin: 0
                        }}
                    >
                        <Flex justifyContent="center" alignItems="center" gap="0.5em">
                            <Heart />
                            MallCord Founder
                        </Flex>
                    </Heading>
                }
            >
                <div>
                    <Flex>
                        <img
                            role="presentation"
                            src="https://iili.io/CfaXwt2.png"
                            alt=""
                            style={{
                                margin: "auto",
                                width: "96px",
                                height: "96px",
                                borderRadius: "50%"
                            }}
                        />
                    </Flex>

                    <div style={{ padding: "1em" }}>
                        <Paragraph>
                            This badge belongs to the founder of MallCord.
                        </Paragraph>
                    </div>
                </div>
            </Modal>
        </ErrorBoundary>
    ));
}

export function MallCordContributorModal() {
    openModal(props => (
        <ErrorBoundary noop onError={() => {
            props.onClose();
        }}>
            <Modal
                {...props}
                title={
                    <Heading
                        tag="h2"
                        style={{
                            width: "100%",
                            textAlign: "center",
                            margin: 0
                        }}
                    >
                        <Flex justifyContent="center" alignItems="center" gap="0.5em">
                            <Heart />
                            MallCord Contributor
                        </Flex>
                    </Heading>
                }
            >
                <div>
                    <Flex>
                        <img
                            role="presentation"
                            src="https://iili.io/C3jZGrg.th.png"
                            alt=""
                            style={{
                                margin: "auto",
                                width: "96px",
                                height: "96px",
                                borderRadius: "50%"
                            }}
                        />
                    </Flex>

                    <div style={{ padding: "1em" }}>
                        <Paragraph>
                            Awarded to contributors helping develop MallCord.
                        </Paragraph>

                        <Paragraph className={Margins.top20}>
                            Thank you for contributing to MallCord!
                        </Paragraph>
                    </div>
                </div>
            </Modal>
        </ErrorBoundary>
    ));
}

export function MallCordDevModal() {
    openModal(props => (
        <ErrorBoundary noop onError={() => {
            props.onClose();
        }}>
            <Modal
                {...props}
                title={
                    <Heading
                        tag="h2"
                        style={{
                            width: "100%",
                            textAlign: "center",
                            margin: 0
                        }}
                    >
                        <Flex justifyContent="center" alignItems="center" gap="0.5em">
                            <Heart />
                            MallCord Dev
                        </Flex>
                    </Heading>
                }
            >
                <div>
                    <Flex>
                        <img
                            role="presentation"
                            src="https://iili.io/CfaMp94.png"
                            alt=""
                            style={{
                                margin: "auto",
                                width: "96px",
                                height: "96px",
                                borderRadius: "50%"
                            }}
                        />
                    </Flex>

                    <div style={{ padding: "1em" }}>
                        <Paragraph>
                            This badge belongs to a MallCord Developer.
                        </Paragraph>

                        <Paragraph className={Margins.top20}>
                            Official developer badge for MallCord staff.
                        </Paragraph>
                    </div>
                </div>
            </Modal>
        </ErrorBoundary>
    ));
}

export function MallCordFriendModal() {
    openModal(props => (
        <ErrorBoundary noop onError={() => {
            props.onClose();
        }}>
            <Modal
                {...props}
                title={
                    <Heading
                        tag="h2"
                        style={{
                            width: "100%",
                            textAlign: "center",
                            margin: 0
                        }}
                    >
                        <Flex justifyContent="center" alignItems="center" gap="0.5em">
                            <Heart />
                            MallCord Friend
                        </Flex>
                    </Heading>
                }
            >
                <div>
                    <Flex>
                        <img
                            role="presentation"
                            src="https://iili.io/CfaXjwl.gif"
                            alt=""
                            style={{
                                margin: "auto",
                                width: "96px",
                                height: "96px",
                                borderRadius: "50%"
                            }}
                        />
                    </Flex>

                    <div style={{ padding: "1em" }}>
                        <Paragraph>
                            This badge belongs to a close friend of MallCord.
                        </Paragraph>
                    </div>
                </div>
            </Modal>
        </ErrorBoundary>
    ));
}
